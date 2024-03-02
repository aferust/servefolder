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

__gshared string folder;
ushort port = 8080;

@onServerInit ServerinoConfig setup(string[] args)
{
    // we can only handle port here, the rest will be handled in onDaemonStart
    auto evar = environment.get("serverinoFolder", null);

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

    auto evar = environment.get("serverinoFolder", null);

    if(evar is null){
        folder = dirName(thisExePath());

        auto helpInformation = getopt( args, std.getopt.config.bundling,
            "directory|d", &folder,
            "port|p", &port
        );
        
        environment["serverinoFolder"] = folder;
        environment["serverinoPort"] = port.to!string;

        log("The server has started to serve from the folder : ", folder);
    }
}

@onWorkerStart void start()
{
    folder = environment["serverinoFolder"];
    port = environment["serverinoPort"].to!ushort;
}

mixin ServerinoMain;

@endpoint void greeter(Request req, Output output)
{
    folder = environment["serverinoFolder"];

    string ruri = req.uri;
    string requestedPath = ruri == "/" ? folder : buildPath(folder, ruri[1..$]).replace('/', dirSeparator);

    if (requestedPath.exists && requestedPath.shouldAllowToServe(folder)){

        if(DirEntry(requestedPath).isDir){
            // a folder is requested

            foreach(indexFile; indexFileNames){
                auto entryPath = buildNormalizedPath(folder, indexFile).replace('/', dirSeparator);

                if (exists(entryPath)){
                    output ~= read(entryPath);
                    return;
                }
            }
            
            // no index html is available, generate the default file browser
            output ~= generateIndexHtml(requestedPath.noEndSep);
            return;
        
        } else {
            // a file is requested
            if(auto valptr = extension(requestedPath) in _mimes)
                output.addHeader("Content-Type", *valptr);
            output ~= requestedPath.read;
            return;
        }

        
    }

    output.status = 404;
    return;

}
