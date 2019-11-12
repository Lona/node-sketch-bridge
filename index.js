const binding = require("node-gyp-build")(__dirname);

module.exports = {
  findFontName: binding.findFontName,
  createStringMeasurer: binding.createStringMeasurer
};
