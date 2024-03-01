# servefolder

A simple HTTP server for static files using serverino.

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