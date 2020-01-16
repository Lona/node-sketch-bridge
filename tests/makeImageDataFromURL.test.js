const { makeImageDataFromURL } = require("../");

const itEncodesAsPNG = (description, ...args) => {
  it(description, async () => {
    const data = makeImageDataFromURL(...args);

    expect(typeof data).toEqual("string");
    expect(Buffer.from(data, "base64")[0]).toBe(0x89); // PNG byte mark
  });
};

describe("makeImageDataFromURL()", () => {
  itEncodesAsPNG("returns a base64-encoded red image");

  itEncodesAsPNG(
    "returns the fetched image as a base64-encoded string",
    "https://www.mjt.me.uk/assets/images/smallest-png/openstreetmap.png"
  );

  itEncodesAsPNG(
    "re-encodes images in other formats to PNG",
    "https://upload.wikimedia.org/wikipedia/commons/3/38/JPEG_example_JPG_RIP_001.jpg"
  );
});
