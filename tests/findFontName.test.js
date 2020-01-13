const { findFontName } = require("../");

describe("findFontName()", () => {
  test("returns font name", () => {
    const fontName = findFontName({
      fontFamily: "Impact",
      fontSize: 18
    });

    expect(fontName).toEqual("Impact");
  });
});
