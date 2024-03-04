module sfaccess;

import std.process;
import std.path;
import std.stdio;
import std.file;
import std.array;
import std.algorithm;
import std.conv;
import std.base64;

import serverino;

import dirfileops;

bool isAuthorizedToAccess(in Request req, ref Output output) {
    auto serverinoFolder = environment["serverinoFolder"];
    string ruri = req.uri;
    string requestedPath = ruri == "/" ? serverinoFolder : buildPath(serverinoFolder, ruri[1..$]).replace('/', dirSeparator);

    if (!exists(buildPath(serverinoFolder, ".sfaccess"))) {
        output.status = 200;
        return true;
    }

    auto file = File(buildPath(serverinoFolder, ".sfaccess"));
    foreach (line; file.byLine) {

        if(line.startsWith('#') || line.empty)
            continue;
        
        auto terms = line.split(":");
        string folderProtected = (cast(string)terms[0]);
        string path = buildPath(serverinoFolder, folderProtected.noStartSep).replace('/', dirSeparator).noEndSep;

        if (requestedPath == path || requestedPath.isChildOf(path)) {
            auto uname = terms[1];
            auto pHash = terms[2];

            string authHeader = req.header.read("authorization");
            if (authHeader.empty || !authHeader.startsWith("Basic ")) {
                output.status = 401;
                return false;
            }

            string base64Credentials = authHeader.split(" ")[1];
            auto reqCredentials = Base64.decode(base64Credentials).split(":");

            string requsername = cast(string) reqCredentials[0];
            string reqpassword = cast(string) reqCredentials[1];
            if (verifyPassword(requsername, reqpassword, uname.to!string, pHash.to!string, folderProtected)) {
                output.status = 200;
                return true;
            } else {
                output.status = 401;
                return false;
            }
        }
    }

    // No matching entry found in .sfaccess file
    output.status = 200;
    return true;
}


bool verifyPassword(string username, string password, string storedUsername, string storedPassword, string subfolder) {
    import std.string;
    import std.digest;
    import std.digest.sha;

    username = username.strip;
    password = password.strip;
    storedUsername = storedUsername.strip;
    storedPassword = storedPassword.strip;

    return (username == storedUsername) && (makeHash(username, password, subfolder).toLower == storedPassword.toLower);
}

string makeHash(string username, string rawpassword, string subfolder){
    import std.digest.sha;
    import std.format;
    return sha256Of(format!"%s:%s:%s"(subfolder, username, rawpassword)).toHexString.dup;
}