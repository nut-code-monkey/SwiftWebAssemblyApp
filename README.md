# Simple example of [swift WebAssebmly](https://www.swift.org/documentation/articles/wasm-getting-started.html) app with [ElementaryUI](https://elementary.codes)


To compile and bundle call from root of Package
```bash
./bundle_wasm.sh WebAssemblyApp
```

For release WASM optimisation `wasm-opt` must be installed:
```bash
brew install binaryen
```

Run it
```bash
   python3 -m http.server 8000 --directory Public/WebAssemblyApp
```

Open `localhost:8000` in browser:
```bash
open http://localhost:8000
``` 
