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
# this config file should be placed in the served folder.
# stored passwords must be of sha256
# example: /your/folder:username:sha256(/your/folder:username:rawpassword)

/testfolder/t1/t2:ferhat:50CF10A5C8826454F07F7F688DF5A0398C96AF2596D5E723A5294218EDAEB158
/testfolder/needauth:andrea:AB305979279EEA1BA510A9213395520E2D6C63ABAD29B8AF00108F3E1D3AF432
```
run ```./servefolder --write-auth yes``` to generate an entry for your .sfaccess file, or use online tools to generate a password.
- building the executable:
cd into the repo folder and run with any d compiler already installed:
```
dub build -b release 
```
