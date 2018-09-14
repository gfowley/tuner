
const loaderUtils = require('loader-utils');
const exec = require('child_process').exec;
const path = require("path")
const glob = require("glob")

module.exports = function(source) {
  const callback = this.async();

  const options = loaderUtils.getOptions(this);

  // paths for file dependencies to be watched paths
  const dirs = options["watch_dirs"]
  if ( dirs ) {
    if ( !Array.isArray( dirs ) ) { dirs = [ dirs ] }
    for ( let dir of dirs ) {
      for ( let file of glob.sync(`${dir}/**/*`,{nodir:true}) ) {
        this.addDependency(file)
      }
    }
  }

  cmd = "rake opal:webpack_build"

  const max_buffer = options["max_buffer"] ? options["max_buffer"] : 10485760  // 10MiB default

  exec(cmd, { maxBuffer: max_buffer }, function (error, stdout, stderr) {
    if (error) { return callback(error, null); }
    callback(null, stdout);
  });

};

