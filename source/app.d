import std.stdio;
import std.conv;
import std.file;
import std.path;
import std.algorithm;
import std.process : environment;
import std.string;
import std.experimental.logger;
import std.getopt;

import core.stdc.stdlib : exit;

import core.runtime: Runtime;

import serverino;

import dirfileops;
import sfaccess;

__gshared string folder;
ushort port = 8080;

@onServerInit ServerinoConfig setup(string[] args)
{
    // we can only handle port here, the rest will be handled in onDaemonStart
    auto evar = environment.get("serverinoFolder", null);

    if(evar is null){

        string unused;

        bool add_auth = false;
        string user = "";
        
        enum Write_auth { no, yes }
        Write_auth write_auth;

        string authfolder;

        auto helpInformation = getopt( args, std.getopt.config.bundling,
            "directory|d", &unused,
            "port|p", &port,
            "write-auth", &write_auth,
            "user", &user,
            "authfolder", &authfolder
        );

        if (helpInformation.helpWanted)
        {
            defaultGetoptPrinter("help information.",
            helpInformation.options);
            exit(0);
        }

        if (write_auth == Write_auth.yes){
            while(authfolder.empty){
                write("> please enter a subfolder to protect: ");
                authfolder = readln().chomp;
            }

            while(user.empty){
                write("> please enter a user name: ");
                user = readln().chomp;
            }
            
            string rawpass;
            while(rawpass is null){
                writef("> please set a password for user %s : ", user);
                rawpass = readln().chomp;
            }

            writeln("Warning: this command does not manage your .sfaccess file.\nYou must manually copy the below text into your .sfaccess file");
            writefln("%s:%s:%s", authfolder, user, makeHash(user, rawpass, authfolder.chomp));
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

    if(!isAuthorizedToAccess(req, output)){
        output.addHeader("WWW-Authenticate", "Basic realm=\"Restricted Area\"");
        return;
    }

    if (requestedPath.exists && requestedPath.shouldAllowToServe(folder)){

        if(DirEntry(requestedPath).isDir){
            // a folder is requested

            foreach(indexFile; indexFileNames){
                auto entryPath = buildNormalizedPath(requestedPath, indexFile).replace('/', dirSeparator);

                if (exists(entryPath)){
                    output ~= read(entryPath);
                    return;
                }
            }
            
            // no index html is available, generate the default file browser

            string c = req.get.read("C", "N");
            string o = req.get.read("O", "A");
            output ~= generateIndexHtml(requestedPath.noEndSep, c, o);
            return;
        
        } else {
            // a file is requested
            output.serveFile(requestedPath);

            return;
        }

        
    }

    output.status = 404;
    return;

}
