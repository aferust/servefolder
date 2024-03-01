import std.stdio;
import std.conv;
import std.file;
import std.path;
import std.algorithm;
import std.process : environment;
import std.json : JSONValue, parseJSON, toJSON;
import std.string;
import std.experimental.logger;
import std.getopt;

import core.stdc.stdlib : exit;

import core.runtime: Runtime;

import serverino;

import dirfileops;
import mimes;

__gshared JSONValue[] _files;
__gshared string folder;
ushort port = 8080;

@onServerInit ServerinoConfig setup(string[] args)
{
    // we can only handle port here, the rest will be handled in onDaemonStart
    auto evar = environment.get("servefolder_paths", null);

    if(evar is null){

        string unused;

        auto helpInformation = getopt( args, std.getopt.config.bundling,
            "directory|d", &unused,
            "port|p", &port
        );

        if (helpInformation.helpWanted)
        {
            defaultGetoptPrinter("help information.",
            helpInformation.options);
            exit(0);
        }
    }
    

    ServerinoConfig sc = ServerinoConfig.create(); // Config with default params
    sc.addListener("0.0.0.0", port);
    sc.setWorkers(4);

   return sc;
}

@onDaemonStart void daemonStart(){

    auto args = Runtime.args();

    auto evar = environment.get("servefolder_paths", null);

    if(evar is null){
        folder = dirName(thisExePath());

        auto helpInformation = getopt( args, std.getopt.config.bundling,
            "directory|d", &folder,
            "port|p", &port
        );

        _files = listFilesRecursively(folder);
        
        JSONValue payload;
        payload.array = _files;
        environment["servefolder_paths"] = toJSON(payload);

        log("The server has started to serve from the folder : ", folder);
    }
}

@onWorkerStart void start()
{
    immutable envvar = environment["servefolder_paths"];
    auto payload = parseJSON(envvar);
    folder = payload.array[0].str;
    _files = payload.array[1..$];
}

mixin ServerinoMain;

@endpoint void greeter(Request req, Output output)
{
    foreach (_jsonfullpath; _files){
        string fullPath = _jsonfullpath.str;
        string uri = fullPath.removeFolderFromPath(folder);

        if(req.uri[1..$] == uri && fullPath.shouldAllowToServe){
            if(auto valptr = extension(fullPath) in _mimes)
                output.addHeader("Content-Type", *valptr);
            output ~= read(fullPath);
            return;
        }
    }

    if (req.uri == "/"){
        foreach(entry; indexFileNames){
            auto entryPath = buildNormalizedPath(folder, entry);
            if (exists(entryPath)){
                output ~= readText(entryPath);
                return;
            }
        }
    }

    output.status = 404;
    return;

}
