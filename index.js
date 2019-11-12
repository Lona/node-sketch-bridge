const binding = require("node-gyp-build")(__dirname);

module.exports = {
  fontNamesForFamily: binding.fontNamesForFamily
};
