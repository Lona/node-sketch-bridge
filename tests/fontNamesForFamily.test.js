const { fontNamesForFamily } = require("../");

test("returns font names", () => {
  const fontNames = fontNamesForFamily("Impact");

  expect(fontNames).toEqual(["Impact"]);
});
