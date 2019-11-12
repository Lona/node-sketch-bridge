const { createStringMeasurer } = require("../");

test("measures an empty string", () => {
  const size = createStringMeasurer([], 400);

  expect(size).toEqual({
    height: 15,
    width: 0
  });
});
