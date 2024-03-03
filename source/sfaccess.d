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
        
        auto lterms = line.split(" ");
        string path = buildPath(serverinoFolder, lterms[0]).replace('/', dirSeparator);

        if (requestedPath == path || requestedPath.isChildOf(path)) {
            auto credentials = lterms[1];
            auto cterms = credentials.split(":");
            auto uname = cterms[0];
            auto pHash = cterms[1];

            string authHeader = req.header.read("authorization");
            if (authHeader.empty || !authHeader.startsWith("Basic ")) {
                output.status = 401;
                return false;
            }

            string base64Credentials = authHeader.split(" ")[1];
            auto reqCredentials = Base64.decode(base64Credentials).split(":");

            string requsername = cast(string) reqCredentials[0];
            string reqpassword = cast(string) reqCredentials[1];
            if (verifyPassword(requsername, reqpassword, uname.to!string, pHash.to!string)) {
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


bool verifyPassword(string username, string password, string storedUsername, string storedPassword) {
    import std.string;
    import std.digest;
    import std.digest.sha;

    username = username.strip;
    password = password.strip;
    storedUsername = storedUsername.strip;
    storedPassword = storedPassword.strip;

    return (username == storedUsername) && (password.sha256Of.toHexString.toLower == storedPassword.toLower);
}
