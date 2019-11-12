const { findFontName } = require("../");

test("returns font name", () => {
  const fontName = findFontName({
    fontFamily: "Impact",
    fontSize: 18
  });

  expect(fontName).toEqual("Impact");
});
