
// before_prepare hook
// run webpack to bundle to www/js directory
// this will be copied by prepare to platform directories

const exec = require('child_process').exec;
const path = require("path")

module.exports = function(context) {
  const deferral = context.requireCordovaModule('q').defer();
  const max_buffer = 10485760
  cmd = "rake webpack:build"
  exec(cmd, { maxBuffer: max_buffer }, function (error, stdout, stderr) {
    if (error) {
      deferral.reject(error);
    }
    deferral.resolve();
  });
  return deferral.promise;
};

// const path = require('path');
// const webpack = require('webpack');
// module.exports = function(context) {
//   const deferral = context.requireCordovaModule('q').defer();
//   const webpackConfigPath = path.resolve(context.opts.projectRoot, 'webpack.config.js');
//   const webpackConfig = require(webpackConfigPath);
//   const compiler = webpack(webpackConfig);
//   compiler.run((err, stats) => {
//     if (err) {
//       deferral.reject(err);
//     }
//     console.log( stats.toString({ chunks: false, colors: true, }));
//     deferral.resolve();
//   });
//   return deferral.promise;
// };


