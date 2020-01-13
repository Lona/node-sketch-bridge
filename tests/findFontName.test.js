const { findFontName } = require("../");

const testEach = cases => {
  test.each(cases)("for %p returns %s", (textStyle, expectedFontName) => {
    expect(findFontName(textStyle)).toEqual(expectedFontName);
  });
};

describe("findFontName()", () => {
  describe("with regular fonts", () => {
    testEach([
      // Regular font
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
      [{ fontFamily: ".AppleSystemUIFont" }, ".SFNSText"],
      [{ fontFamily: "System" }, ".SFNSText"],
      [{ fontFamily: "System", fontSize: 12 }, ".SFNSText"],
      [{ fontFamily: "System", fontWeight: "bold" }, ".SFNSText-Bold"],
      [{ fontFamily: "System", fontStyle: "italic" }, ".SFNSText-Italic"],
      [{ fontFamily: "System", fontWeight: "bold", fontStyle: "italic" }, ".SFNSText-BoldItalic"],
      [{ fontFamily: "System", fontStyle: "oblique" }, ".SFNSText-Italic"]
    ]);

    describe("for font sizes >= 20, it switches to SF Display", () => {
      testEach([
        [{ fontFamily: ".AppleSystemUIFont", fontSize: 20 }, ".SFNSDisplay"],
        [{ fontFamily: "System", fontSize: 20 }, ".SFNSDisplay"]
      ]);
    });
  });

  describe("missing fonts default to the system font", () => {
    testEach([
      [{ fontFamily: "MissingFont" }, ".SFNSText"],
      [{ fontFamily: "MissingFont", fontSize: 20 }, ".SFNSDisplay"]
    ]);
  });

  describe("when the fontFamily property is missing", () => {
    // TODO(lordofthelake): Does this make sense, considering the missing font case?
    // Shouldn't it default to the system font?
    it("defaults to Helvetica", () => {
      expect(findFontName({})).toEqual("Helvetica");
    });
  });

  describe("when the fontFamily property is blank", () => {
    // TODO(lordofthelake): Coherence problem as above.
    it("defaults to the system font", () => {
      expect(findFontName({ fontFamily: "" })).toEqual(".SFNSText");
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
