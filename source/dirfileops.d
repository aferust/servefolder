module dirfileops;

import std.file;
import std.stdio;
import std.path;
import std.json;
import std.algorithm;
import std.string;
import std.exception;

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
            if (dirEntry.isDir && !dirEntry.name.startsWith(".") && !dirEntry.name.startsWith("_")) {
                // Add subdirectories to explore
                directoriesToExplore.insertFront(dirEntry.name);
            } else {
                filePATHS.array ~= JSONValue(dirEntry.name);
            }
        }
    }

    return filePATHS.array;
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