require "bundler"
Bundler.require

def opal_build
  Opal.append_path "app"
  Opal.append_path "lib"
  Opal::Builder.build("index").to_s
end

namespace :opal do

  desc "Remove built files"
  task :clean do
    FileUtils.rm_f "www/js/index.js"
  end

  desc "Opal build to www/js/index.js"
  task :build => [ :clean ] do
    FileUtils.mkdir_p 'www/js'
    File.binwrite "www/js/index.js", opal_build
  end

  desc "Opal build to stdout - for use by webpack loader"
  task :webpack_build do
    $stdout.sync = true
    $stdout.write opal_build
  end

end

namespace :webpack do

  desc "Remove built files"
  task :clean do
    FileUtils.rm_f "www/js/index.js"
  end

  desc "build"
  task :build do
    exec(
      "./node_modules/.bin/webpack --progress --mode=development"
    )
  end

  desc "server"
  task :server do
    exec(
      "./node_modules/.bin/webpack-dev-server --progress --mode=development --watch "
    )
  end

end

