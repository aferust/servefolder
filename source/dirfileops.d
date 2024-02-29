module dirfileops;

import std.file;
import std.stdio;
import std.path;
import std.algorithm;
import std.string;
import std.exception;

string[] listFilesRecursively(string directory) {
    import std.container : SList;

    string[] filePATHS;
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
                filePATHS ~= dirEntry.name;
            }
        }
    }

    return filePATHS;

    /+ typical recursion version here:
    string[] filePATHS;
    foreach (dirEntry; dirEntries(directory, SpanMode.depth)) {
        if (dirEntry.isDir) {
            if (!dirEntry.name.startsWith(".") && !dirEntry.name.startsWith("_")) {
                listFilesRecursively(dirEntry.name);
            }
        } else {
            filePATHS ~= dirEntry.name;
        }
    }

    return filePATHS;
    +/
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

void appendLinesToFile(string filePath, string[] lines)
{
    auto file = File(filePath, "a");

    if (!file.isOpen())
    {
        // Handle error opening the file
        writeln("Error: Unable to open file for appending.");
        return;
    }

    string pload;
    foreach (line; lines)
    {
        pload ~= line ~ '\n';
    }

    file.write(pload);

    file.close();
}

string[] readPathsFromTmpFile(string filePath)
{
    string[] paths;

    auto file = File(filePath);

    if (!file.isOpen())
    {
        throw new Exception("Error: Unable to open tmp file for reading.");
        return null;
    }

    //bool firstL = false;

    foreach (line; file.byLine())
    {
        
        /*if(!line.empty)
            paths ~= !firstL ? line[0..$].idup : line[0..$-1].idup;
        firstL = true;*/
        paths ~= line.endsWith('\r') ? line[0..$-1].idup : line.idup;
    }

    file.close();
    return paths; // the first line should be the folder that we serve.
}