const { makeImageDataFromURL } = require("../");

test("returns a default image", () => {
  const data = makeImageDataFromURL();

  expect(typeof data).toEqual("string");
});

test("returns a fetched image", () => {
  const data = makeImageDataFromURL(
    "https://www.mjt.me.uk/assets/images/smallest-png/openstreetmap.png"
  );

  expect(typeof data).toEqual("string");
});
