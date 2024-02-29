import std.stdio;
import std.conv;
import std.file;
import std.path;
import std.algorithm;
import std.string;
import std.experimental.logger;

import core.runtime: Runtime;

import serverino;

import dirfileops;
import mimes;

enum tmpFileName = "tmp_servefolder.txt";

__gshared string[] _files;
__gshared string folder;
ushort port = 8080;

@onServerInit ServerinoConfig setup(string[] _args)
{
	const args = _args;
	
	if(!tmpFileName.exists){
		if(args.length > 1){
			folder = args.length > 1 ? args[1] : dirName(thisExePath());
			if(args.length > 2)
    			port = args[2].to!ushort;
		}
		
		(folder ~ "\n").toFile(tmpFileName);
		_files = listFilesRecursively(folder);
		appendLinesToFile(tmpFileName, _files);
	}

    ServerinoConfig sc = ServerinoConfig.create(); // Config with default params
    sc.addListener("0.0.0.0", port);
    sc.setWorkers(4);

   return sc;
}

@onWorkerStart void start()
{
	string[] payload = readPathsFromTmpFile(tmpFileName);
	folder = payload[0];
	_files = payload[1..$]; //listFilesRecursively(folder);
}

@onDaemonStart daemonStart(){
	
}

mixin ServerinoMain;

@endpoint void greeter(Request req, Output output)
{
    foreach (string fullPath; _files){
		string uri = "/";
		uri ~= fullPath.removeFolderFromPath(folder);

		if(req.uri == uri){
			if(auto valptr = extension(fullPath) in _mimes)
				output.addHeader("Content-Type", *valptr);
			output ~= read(fullPath);
			return;
		}
    }

	if (req.uri == "/"){
		foreach(entry; ["index.html", "index.htm"]){
			auto entryPath = buildNormalizedPath(folder, "index.html");
			if (exists(entryPath)){
				output ~= readText(entryPath);
				return;
			}
		}
	}

	output.status = 404;
	return;

}
