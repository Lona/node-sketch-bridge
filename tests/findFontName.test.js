const { findFontName } = require("../");

const testEach = cases => {
  test.each(cases)("for %p returns %s", (textStyle, expectedFontName) => {
    if (expectedFontName instanceof RegExp) expect(findFontName(textStyle)).toMatch(expectedFontName);
    else expect(findFontName(textStyle)).toEqual(expectedFontName);
  });
};

describe("findFontName()", () => {
  describe("with regular fonts", () => {
    testEach([
      // Regular font, one style available
      [{ fontFamily: "Impact" }, "Impact"],
      [{ fontFamily: "Impact", fonstStyle: "italic" }, "Impact"],

      // Font with more variants
      [{ fontFamily: "Helvetica", fontWeight: "bold" }, "Helvetica-Bold"],
      [{ fontFamily: "Helvetica", fontStyle: "italic" }, "Helvetica-Oblique"],
      [{ fontFamily: "Helvetica", fontStyle: "oblique" }, "Helvetica-Oblique"],
      [{ fontFamily: "Helvetica", fontWeight: "300" }, "Helvetica-Light"],
      [{ fontFamily: "Helvetica", fontWeight: "300", fontStyle: "italic" }, "Helvetica-LightOblique"]
    ]);

    describe("when a weight is missing, it uses the next one available", () => {
      testEach([
        [{ fontFamily: "Helvetica", fontWeight: "900" }, "Helvetica-Bold"],
        [{ fontFamily: "Helvetica", fontWeight: "600" }, "Helvetica-Bold"],
        [{ fontFamily: "Helvetica", fontWeight: "500" }, "Helvetica-Bold"],
        [{ fontFamily: "Helvetica", fontWeight: "200" }, "Helvetica-Light"]
      ]);
    });
  });

  describe("for a system font, uses SF Text", () => {
    testEach([
      [{ fontFamily: ".AppleSystemUIFont" }, /^\.SFNS\w*(-Regular)?$/],
      [{ fontFamily: "System" }, /^\.SFNS/],
      [{ fontFamily: "System", fontSize: 12 }, /^\.SFNS\w*(-Regular)?$/],
      [{ fontFamily: "System", fontWeight: "bold" }, /^\.SFNS\w*-Bold$/],
      [{ fontFamily: "System", fontStyle: "italic" }, /^\.SFNS\w*-(Regular)?Italic$/],
      [{ fontFamily: "System", fontWeight: "bold", fontStyle: "italic" }, /^\.SFNS\w*-BoldItalic$/],
      [{ fontFamily: "System", fontStyle: "oblique" }, /^\.SFNS\w*-(Regular)?Italic$/]
    ]);
  });

  describe("missing fonts default to the system font", () => {
    testEach([
      [{ fontFamily: "MissingFont" }, /^\.SFNS\w*(-Regular)?$/],
      [{ fontFamily: "MissingFont", fontWeight: "bold" }, /^\.SFNS\w*-Bold$/]
    ]);
  });

  describe("when the fontFamily property is missing", () => {
    it("defaults to the system font", () => {
      expect(findFontName({})).toMatch(/^\.SFNS\w*(-Regular)?$/);
      expect(findFontName({ fontWeight: "bold" })).toMatch(/^\.SFNS\w*-Bold$/);
    });
  });

  describe("when the fontFamily property is blank", () => {
    it("defaults to the system font", () => {
      expect(findFontName({ fontFamily: "" })).toMatch(/^\.SFNS\w*(-Regular)?$/);
      expect(findFontName({ fontFamily: "", fontWeight: "bold" })).toMatch(/^\.SFNS\w*-Bold$/);
    });
  });

  describe("when the fontWeight is invalid", () => {
    it("when given a number, throws an error", () => {
      // TODO(lordofthelake): Shouldn't this case be handled more gracefully?
      expect(() => findFontName({ fontWeight: 300 })).toThrow("Could not get string length");
    });

    it("when given an invalid string, defaults to regular", () => {
      expect(findFontName({ fontFamily: "Helvetica", fontWeight: "bolder" })).toEqual("Helvetica");
    });
  });

  describe("when the fontStyle is invalid", () => {
    it("returns the regular version", () => {
      expect(findFontName({ fontFamily: "Helvetica", fontStyle: "happy" })).toEqual("Helvetica");
    });
  });
});
