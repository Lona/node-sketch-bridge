# Node Sketch Bridge

This package exposes the macOS APIs needed for generating Sketch files. It relies on a node native module written in Obj-C.

```
npm install --save node-sketch-bridge
```

## API

### `findFontName`

```js
const { findFontName } = require("node-sketch-bridge");

const fontName = findFontName({
  fontFamily: "Helvetica",
  fontStyle: "italic"
});

console.log(fontName); // "Helvetica-Oblique"
```

:warning: Caveats:

- If the `fontFamily` property is missing, or the requested font is not installed, it will fall back to the default system
  provided by the OS (usually, something from the _San Francisco_ family). The specific font returned changes across
  macOS versions and for different font sizes.

### `createStringMeasurer`

```js
const { createStringMeasurer } = require("node-sketch-bridge");

const size = createStringMeasurer(
  [
    {
      content: "Hello",
      textStyles: {
        fontFamily: "Helvetica",
        fontSize: 16,
        fontWeight: "bold",
        fontStyle: "italic",
        lineHeight: 23,
        letterSpacing: 1,
        textDecoration: "underline",
        textAlign: "left"
      }
    }
  ],
  400
);

console.log(size); // "{ width: ..., height: ... }"
```

:warning: Caveats:

- When the `lineHeight` property is not specified, the default used by this function may be different from what Sketch
  uses by default for certain font families. This might result in a bounding box calculation that is different from
  what Sketch would display. For best results, it's advised to always specify the `lineHeight` explicitly.
- Support for `textTransform` property is missing at the moment. When specified, the requested text transformation
  will not be taken into account when computing the bounding box.

### `makeImageDataFromURL`

```js
const { makeImageDataFromURL } = require("node-sketch-bridge");

const base64EncodedImage = makeImageDataFromURL("https://placekitten.com/200/300");

// The buffer will contain the PNG-encoded image of a kitten. Meow.
const imageBuffer = Buffer.from(base64EncodedImage, "base64");
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
