const { createStringMeasurer } = require("../");

const testBody = ({ content, within, expectedWidth, expectedHeight, ...textStyles }) => {
  const { width, height } = createStringMeasurer([{ content, textStyles }], within);

  // TODO(lordofthelake): Sketch uses round numbers for widths.
  // Considering that these are pixels, would it make sense to return rounded numbers too?
  const roundedUpWidth = Math.ceil(width);

  expect(roundedUpWidth).toBe(expectedWidth);
  expect(height).toBe(expectedHeight);
};

const testDescription = (...parameters) => {
  let textStyles = parameters.includes("fontFamily") ? "$fontFamily" : "[System font]";
  if (parameters.includes("fontWeight")) textStyles += " $fontWeight";
  if (parameters.includes("fontStyle")) textStyles += " $fontStyle";
  if (parameters.includes("fontSize")) textStyles += " $fontSize\u200bpx";
  if (parameters.includes("lineHeight")) textStyles += "/$lineHeight\u200bpx";
  if (parameters.includes("letterSpacing")) textStyles += " [$letterSpacing\u200bpx letter spacing]";
  if (parameters.includes("textAlign")) textStyles += ", $textAlign-aligned,";

  return `within $within\u200bpx, measures \`$content\` in ${textStyles} to be $expectedWidth✕$expectedHeight\u200bpx`;
};

describe("createStringMeasurer()", () => {
  it("measures an empty string", () => {
    const size = createStringMeasurer([], 400);

    expect(size).toEqual({
      height: 15,
      width: 0
    });
  });

  describe("when setting a line height", () => {
    test.each`
      content    | fontFamily          | fontSize | lineHeight | within | expectedWidth | expectedHeight
      ${"Hello"} | ${"Helvetica"}      | ${14}    | ${16}      | ${400} | ${32}         | ${16}
      ${"Hello"} | ${"Helvetica"}      | ${24}    | ${26}      | ${400} | ${55}         | ${26}
      ${"Hello"} | ${"Helvetica"}      | ${72}    | ${74}      | ${400} | ${165}        | ${74}
      ${"Hello"} | ${"Helvetica"}      | ${120}   | ${122}     | ${400} | ${274}        | ${122}
      ${"Hello"} | ${"Impact"}         | ${24}    | ${26}      | ${400} | ${52}         | ${26}
      ${"Hello"} | ${"Helvetica Neue"} | ${24}    | ${26}      | ${400} | ${55}         | ${26}
      ${"Hello"} | ${"Georgia"}        | ${24}    | ${26}      | ${400} | ${58}         | ${26}
    `(testDescription("fontFamily", "fontSize", "lineHeight"), testBody);
  });

  describe("when spaces are present", () => {
    test.each`
      content   | fontFamily     | fontSize | lineHeight | within | expectedWidth | expectedHeight
      ${"."}    | ${"Helvetica"} | ${24}    | ${28}      | ${400} | ${7}          | ${28}
      ${".."}   | ${"Helvetica"} | ${24}    | ${28}      | ${400} | ${14}         | ${28}
      ${". ."}  | ${"Helvetica"} | ${24}    | ${28}      | ${400} | ${21}         | ${28}
      ${".  ."} | ${"Helvetica"} | ${24}    | ${28}      | ${400} | ${27}         | ${28}
    `(testDescription("fontFamily", "fontSize", "lineHeight"), testBody);
  });

  describe("when the text width exceeds the available space", () => {
    test.each`
      content          | fontFamily     | fontSize | lineHeight | within | expectedWidth | expectedHeight
      ${"Hello"}       | ${"Helvetica"} | ${24}    | ${29}      | ${100} | ${55}         | ${29}
      ${"Hello Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${200} | ${117}        | ${29}
      ${"Hello Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${100} | ${62}         | ${58}
      ${"HelloHello"}  | ${"Helvetica"} | ${24}    | ${29}      | ${100} | ${97}         | ${58}
    `(testDescription("fontFamily", "fontSize", "lineHeight"), testBody);
  });

  describe("when using different font weights and styles", () => {
    test.each`
      content    | fontFamily     | fontSize | lineHeight | within | fontWeight  | fontStyle   | expectedWidth | expectedHeight
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${100} | ${"normal"} | ${"normal"} | ${55}         | ${29}
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${100} | ${"normal"} | ${"italic"} | ${55}         | ${29}
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${100} | ${"bold"}   | ${"normal"} | ${59}         | ${29}
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${100} | ${"bold"}   | ${"italic"} | ${59}         | ${29}
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${100} | ${"300"}    | ${"normal"} | ${55}         | ${29}
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${100} | ${"300"}    | ${"italic"} | ${55}         | ${29}
    `(testDescription("fontFamily", "fontSize", "fontWeight", "fontStyle", "lineHeight"), testBody);
  });

  describe("when using different alignments", () => {
    const loremIpsum =
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";

    test.each`
      content       | fontFamily     | fontSize | lineHeight | textAlign    | within | expectedWidth | expectedHeight
      ${loremIpsum} | ${"Helvetica"} | ${24}    | ${29}      | ${"left"}    | ${200} | ${200}        | ${232}
      ${loremIpsum} | ${"Helvetica"} | ${24}    | ${29}      | ${"right"}   | ${200} | ${200}        | ${232}
      ${loremIpsum} | ${"Helvetica"} | ${24}    | ${29}      | ${"center"}  | ${200} | ${200}        | ${232}
      ${loremIpsum} | ${"Helvetica"} | ${24}    | ${29}      | ${"justify"} | ${200} | ${200}        | ${232}
    `(testDescription("fontFamily", "fontSize", "textAlign", "lineHeight"), testBody);
  });

  describe("when using letter spacing", () => {
    test.each`
      content    | fontFamily     | fontSize | lineHeight | letterSpacing | within | expectedWidth | expectedHeight
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${-1}         | ${200} | ${50}         | ${29}
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${0}          | ${200} | ${55}         | ${29}
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${1}          | ${200} | ${60}         | ${29}
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${10}         | ${200} | ${105}        | ${29}
      ${"Hello"} | ${"Helvetica"} | ${24}    | ${29}      | ${20}         | ${200} | ${155}        | ${29}
    `(testDescription("fontFamily", "fontSize", "letterSpacing", "lineHeight"), testBody);
  });
});
