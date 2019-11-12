# Node Sketch Bridge

This package exposes the macOS APIs needed for generating Sketch files. It relies on a node native module written in Obj-C.

```
npm install --save node-sketch-bridge
```

## Development

First, run `npm install`.

To develop in Xcode, you'll need to generate an Xcode project. The following worked for me on Mojave:

```bash
npm install --global node-gyp

node-gyp --python /usr/local/bin/python2 configure -- -f xcode

node-gyp build
```

Then, `open build/binding.xcodeproj`.

## License

MIT
