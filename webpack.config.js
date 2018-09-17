var path = require("path")

module.exports = (env,argv) => {
  // console.log(argv)
  return {
    entry: './app/index.rb',
    output: {
      filename: 'index.js',
      path: path.resolve(__dirname, 'www/js'),
    },
    module: {
      rules: [
        { 
          test: /\.rb$/, 
          loader: path.resolve('./iqeo_opal_loader.js'),
          options: {
            watch_dirs: [ "app", "lib" ]
          }
        }
      ]
    },
    devServer: {
      // webpack js bundle (ruby->js) served from http://.../js/
      publicPath: '/js/',
      // non-webpack content served in order from...
      // www first for non-ruby source ( js, html, css, img ) changes
      // platforms/browser/www second for cordova platform stuff
      contentBase: [
        path.resolve(__dirname, 'www'),
        path.resolve(__dirname, 'platforms/browser/www')
      ],
      port: 8000
      // // TODO: multiple reloads while index.html is edited before saving
      // // consider html-loader for .html files approach ?
      // watchContentBase: true,
      // watchOptions: {
      //   ignored: /node_modules/
      // }
    }
  }
}

