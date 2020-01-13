const { promisify } = require("util");
const { readFile, writeFile } = require("fs");
const path = require("path");
const { makeImageDataFromURL } = require("../");

const readFileAsync = promisify(readFile);
const writeFileAsync = promisify(writeFile);

describe("makeImageDataFromURL()", () => {
  it("returns a base64-encoded red image", async () => {
    const data = makeImageDataFromURL();
    const fixture = await readFileAsync(path.resolve(__dirname, "fixtures/error.png"));

    expect(typeof data).toEqual("string");
    expect(Buffer.from(data, "base64")).toEqual(fixture);
  });

  it("returns the fetched image as a base64-encoded string", async () => {
    // TODO(lordofthelake): The original file is 103 bytes, but after decoding/re-encoding
    // it becomes 1144 bytes (~1kb). Would be better to skip re-encoding?
    const data = makeImageDataFromURL("https://www.mjt.me.uk/assets/images/smallest-png/openstreetmap.png");
    const fixture = await readFileAsync(path.resolve(__dirname, "fixtures/openstreetmap-reencoded.png"));

    expect(typeof data).toEqual("string");
    expect(Buffer.from(data, "base64")).toEqual(fixture);
  });

  it("re-encodes images in other formats to PNG", async () => {
    // TODO(lordofthelake): The original file is ~1kb, but with the PNG conversion it becomes 37kb.
    // Is it necessary to convert everything to PNG?
    const data = makeImageDataFromURL(
      "https://upload.wikimedia.org/wikipedia/commons/3/38/JPEG_example_JPG_RIP_001.jpg"
    );
    const fixture = await readFileAsync(path.resolve(__dirname, "fixtures/jpeg.png"));

    expect(typeof data).toEqual("string");
    expect(Buffer.from(data, "base64")).toEqual(fixture);
  });
});
