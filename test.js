const tape = require("tape");
const { fontNamesForFamily } = require("./");

tape("fontNamesForFamily", function(t) {
  const result = fontNamesForFamily("Helvetica");
  result.forEach((item, i) => {
    console.log("item", i, item);
  });
  t.pass("did not crash");
  t.end();
});
