module dirfileops;

import std.file;
import std.stdio;
import std.path;
import std.json;
import std.algorithm;
import std.string;
import std.exception;
import std.typecons;
import std.array;

static immutable indexFileNames = ["index.html", "index.htm"];

auto noEndSep(string u){
    if(u.empty)
        return u;
    
    return u.endsWith('/') || u.endsWith('\\')  ? u[0..u.length-1] : u;
}

auto noStartSep(string u){
    if(u.empty)
        return u;
    
    return u.startsWith('/') || u.startsWith('\\')  ? u[1..$] : u;
}

bool shouldAllowToServe(string _path, string folderServed){
    if(_path == folderServed)
        return true;
    
    auto path = relativePath(_path, folderServed).replace('\\', '/');

    foreach(sp; pathSplitter(path)){
        if(sp.startsWith('.') || sp.startsWith(".."))
            return false;
    }

    return true;
}

import std.datetime;

string generateIndexHtml(string folderPath) {
    import std.conv : to;
    import std.process;

    string servingFolder = environment["serverinoFolder"].replace('\\', '/');

    string folderUri = relativePath(folderPath, servingFolder).replace('\\', '/');
    
    string parentUri = buildNormalizedPath('/' ~ folderUri, "../");

    string htmlContent = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n";
    htmlContent ~= "<html>\n <head>\n  <title>Index of " ~ folderPath ~ "</title>\n </head>\n <body>\n";
    htmlContent ~= "<h1>Index of /" ~ folderUri ~ "</h1>\n  <table>\n   <tr><th valign=\"top\"> </th><th><a href=\"?C=N;O=D\">Name</a></th><th><a href=\"?C=M;O=A\">Last modified</a></th><th><a href=\"?C=S;O=A\">Size</a></th></tr>\n   <tr><th colspan=\"4\"><hr></th></tr>\n";
    
    // Parent directory link
    string parentDirLink = "<tr><td valign=\"top\">"~backIcon~"</td><td><a href=\"" ~ parentUri ~ "\">Parent Directory</a></td><td>&nbsp;</td><td align=\"right\">  - </td></tr>\n";
    htmlContent ~= parentDirLink;
    
    // File links
    foreach (dirEntry; dirEntries(folderPath, SpanMode.shallow, false)) if(dirEntry.name.shouldAllowToServe(servingFolder)) {
        string anEntry;
        auto lastModified = dirEntry.timeLastModified;
        string lastModifiedStr = lastModified.toISOExtString();

        if (dirEntry.isDir){
            string _folderName = dirEntry.name.baseName;
            string _folderUri = '/' ~ folderUri ~ '/' ~ _folderName;
            anEntry = "<tr><td valign=\"top\">" ~ folderIcon ~ "</td><td><a href=\"" ~ _folderUri ~ "\">" ~ _folderName ~ "/</a></td><td align=\"right\">" ~ lastModifiedStr ~ " </td><td align=\"right\">  - </td></tr>";
        } else {
            ulong fileSize = dirEntry.size;
            
            string fileName = dirEntry.name.noEndSep.baseName;
            //string fileExtension = fileName.extension.toLower;
            string fileUri = '/' ~ folderUri ~ '/' ~ fileName;

            anEntry = "<tr><td valign=\"top\">" ~ fileIcon ~ "</td><td><a href=\"" ~ fileUri ~ "\">" ~ fileName ~ "</a></td><td align=\"right\">" ~ lastModifiedStr ~ "</td><td align=\"right\">" ~ fileSize.to!string ~ "</td></tr>\n";
        }
        htmlContent ~= anEntry;
    }
    
    // Closing tags
    htmlContent ~= "   <tr><th colspan=\"4\"><hr></th></tr>\n</table>\n<address>Serverino Server at localhost Port " ~ environment["serverinoPort"] ~ "</address>\n</body></html>";
    
    return htmlContent;
}


enum fileIcon =`<svg width="24" height="24">
    <path d="M6 2c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6H6zm6 4v4h4l-4-4zM6 20V4h5v5h5v11H6z"/>
</svg>`;

enum folderIcon =`<svg width="24" height="24">
    <path d="M21 6H12l-2-2H3c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h18c1.1 0 2-.9 2-2V8c0-1.1-.9-2-2-2zm-2 14H5V8h14v12zM7 17h10v-2H7v2zm0-4h10v-2H7v2zm0-4h7V7H7v2z"/>
</svg>`;

enum backIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
    <path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"/>
</svg>`;