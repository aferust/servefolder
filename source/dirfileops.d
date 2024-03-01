module dirfileops;

import std.file;
import std.stdio;
import std.path;
import std.json;
import std.algorithm;
import std.string;
import std.exception;

static immutable indexFileNames = ["index.html", "index.htm"];

JSONValue[] listFilesRecursively(string directory) {
    // use heap stack for recursion to avoid hitting the stack limits
    import std.container : SList;

    JSONValue filePATHS; 
    filePATHS.array = [JSONValue(directory)];

    SList!string directoriesToExplore; // Maintain a list of directories to explore

    directoriesToExplore.insertFront(directory);

    while (!directoriesToExplore.empty) {
        auto currentDirectory = directoriesToExplore.front;
        directoriesToExplore.removeFront();

        foreach (dirEntry; dirEntries(currentDirectory, SpanMode.depth)) {
            if (dirEntry.isDir && dirEntry.name.shouldAllowToServe) {
                // Add subdirectories to explore
                directoriesToExplore.insertFront(dirEntry.name);
            } else {
                
                if(dirEntry.name.shouldAllowToServe && dirEntry.name.dirName.shouldAllowToServe){
                    filePATHS.array ~= JSONValue(dirEntry.name);
                }
                    
            }
        }
    }

    return filePATHS.array;
}

bool shouldAllowToServe(string path){

    if(!DirEntry(path).isDir){
        // is a file but file name starts with '.'
        if(baseName(path, extension(path)).startsWith('.')) 
            return false;
        // is am index file but the parent folder starts with '.'
        if(indexFileNames.canFind(path.baseName) && path.dirName.startsWith('.'))
            return false;
    }
    
    if(path.baseName.startsWith(".") || path.dirName.startsWith("."))
        return false;
    if(path.baseName.startsWith("_") || path.dirName.startsWith("_"))
        return false;

    return true;
}

string removeFolderFromPath(string filePath, string folderPath)
{
    import std.algorithm : startsWith;
    import std.string : indexOf, startsWith;
    import std.array;
    import std.path : dirSeparator;
    import std.algorithm;
    import std.conv : to;
    
    // Replace Windows backslashes with forward slashes for consistency
    folderPath = folderPath.replace('\\', '/');
    filePath = filePath.replace('\\', '/');

    // Ensure folderPath ends with a directory separator
    if (!folderPath.endsWith('/'))
        folderPath ~= '/';

    // Check if filePath starts with folderPath
    if (filePath.startsWith(folderPath))
    {
        // Get the index after the folderPath
        size_t startIndex = folderPath.length;

        // If filePath starts with a directory separator after the folderPath, skip it
        if (filePath[startIndex].to!string == dirSeparator)
            startIndex++;

        // Return the substring after folderPath
        return filePath[startIndex .. $];
    }

    // If filePath does not start with folderPath, return the original path
    return filePath;
}