module dirfileops;

import std.file;
import std.stdio;
import std.path;
import std.algorithm;
import std.string;
import std.exception;
import std.typecons;
import std.array;
import std.process;

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

bool isChildOf(string childEntry, string parentEntry) {
    return childEntry.startsWith(parentEntry);
}

import std.datetime;

enum utfGoParent = "&#11152;";
enum utfFolder = "&#x1F4C1;";
enum utfFile = "&#x1F5CE;";

string generateIndexHtml(string folderPath, string sortby = "N", string order = "A") {
    import std.conv : to;
    
    string servingFolder = environment["serverinoFolder"].replace('\\', '/');
    string folderUri = relativePath(folderPath, servingFolder).replace('\\', '/');
    string parentUri = buildNormalizedPath('/' ~ folderUri, "../");
    
    string nameSortQuery = "?C=N";
    string modifiedSortQuery = "?C=M";
    string sizeSortQuery = "?C=S";

    if (order == "A") {
        nameSortQuery ~= "&O=D";
        modifiedSortQuery ~= "&O=D";
        sizeSortQuery ~= "&O=D";
    } else if (order == "D") {
        nameSortQuery ~= "&O=A";
        modifiedSortQuery ~= "&O=A";
        sizeSortQuery ~= "&O=A";
    }

    string nameHeaderLink = "<a href=\"" ~ nameSortQuery ~ "\">Name</a>";
    string modifiedHeaderLink = "<a href=\"" ~ modifiedSortQuery ~ "\">Last modified</a>";
    string sizeHeaderLink = "<a href=\"" ~ sizeSortQuery ~ "\">Size</a>";

    string htmlContent = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 3.2 Final//EN\">\n";
    htmlContent ~= "<html>\n <head>\n  <title>Index of " ~ folderPath ~ "</title>\n </head>\n <body>\n";
    htmlContent ~= "<h1>Index of /" ~ folderUri ~ "</h1>\n  <table>\n   <tr><th valign=\"top\"> </th><th>" ~ nameHeaderLink ~ "</th><th>" ~ modifiedHeaderLink ~ "</th><th>" ~ sizeHeaderLink ~ "</th></tr>\n   <tr><th colspan=\"4\"><hr></th></tr>\n";
    
    // Parent directory link
    string parentDirLink = "<tr><td valign=\"top\">"~utfGoParent~"</td><td><a href=\"" ~ parentUri ~ "\">Parent Directory</a></td><td>&nbsp;</td><td align=\"right\">  - </td></tr>\n";
    htmlContent ~= parentDirLink;
    
    // Directory entries
    auto entries = dirEntries(folderPath, SpanMode.shallow, false)
                      .filter!(entry => entry.name.shouldAllowToServe(servingFolder))
                      .array;

    // Sort the directory entries based on the specified criteria
    if (sortby == "N")
        entries.sort!((a, b) => (order == "A") ? a.name < b.name : a.name > b.name);
    else if (sortby == "M")
        entries.sort!((a, b) => (order == "A") ? a.timeLastModified < b.timeLastModified : a.timeLastModified > b.timeLastModified);
    else if (sortby == "S")
        entries.sort!((a, b) => (order == "A") ? a.size < b.size : a.size > b.size);

    // File links
    foreach (dirEntry; entries) {
        string anEntry;
        auto lastModified = dirEntry.timeLastModified;
        string lastModifiedStr = lastModified.toISOExtString();

        if (dirEntry.isDir){
            string _folderName = dirEntry.name.baseName;
            string _folderUri = '/' ~ folderUri ~ '/' ~ _folderName;
            anEntry = "<tr><td valign=\"top\">"~utfFolder~"</td><td><a href=\"" ~ _folderUri ~ "\">" ~ _folderName ~ "/</a></td><td align=\"right\">" ~ lastModifiedStr ~ " </td><td align=\"right\">  - </td></tr>";
        } else {
            ulong fileSize = dirEntry.size;
            
            string fileName = dirEntry.name.noEndSep.baseName;
            string fileUri = '/' ~ folderUri ~ '/' ~ fileName;

            anEntry = "<tr><td valign=\"top\">"~utfFile~"</td><td><a href=\"" ~ fileUri ~ "\">" ~ fileName ~ "</a></td><td align=\"right\">" ~ lastModifiedStr ~ "</td><td align=\"right\">" ~ fileSize.to!string ~ "</td></tr>\n";
        }
        htmlContent ~= anEntry;
    }
    
    // Closing tags
    htmlContent ~= "   <tr><th colspan=\"4\"><hr></th></tr>\n</table>\n<address>Serverino Server at localhost Port " ~ environment["serverinoPort"] ~ "</address>\n</body></html>";
    
    return htmlContent;
}