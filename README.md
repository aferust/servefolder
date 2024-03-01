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

- building the executable:
cd into the repo folder and run with any d compiler already installed:
```
dub build -b release 
```
