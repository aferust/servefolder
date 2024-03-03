# servefolder

A simple and extremely lightweight HTTP server for static files using [serverino](https://github.com/trikko/serverino).

run to serve /your/path on port 3000:
```
servefolder -d /your/path -p 3000

// or of course

servefolder --directory=/your/path --port=3000
```

run to serve /your/path on the default port 8080:
```
servefolder -d /your/path
```

run to serve the current exe folder on the default port 8080:
```
servefolder
```

- to display help run: ```servefolder -h```

Use a .sfaccess file to protect your folders vith basic auth:
```
# Set authorization to your folders here.
# this folder should be placed in the served folder.
# stored passwords must be of sha256
# example: /your/folder/ username:a_password_as_sha256_hex_string

testfolder/t1/t2 ferhat:6b51d431df5d7f141cbececcf79edf3dd861c3b4069f0b11661a3eefacbba918
testfolder/needauth andrea:6B51D431DF5D7F141CBECECCF79EDF3DD861C3B4069F0B11661A3EEFACBBA918
```

- building the executable:
cd into the repo folder and run with any d compiler already installed:
```
dub build -b release 
```
