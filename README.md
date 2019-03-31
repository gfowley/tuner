
# 

Usage:

# 1
# build app from www to platforms/browser/www  
# cordova build = cordova prepare + compile
# cordova hook before_prepare runs scripts/before_prepare.js -> rake webpack:build to create bundle in www/js

cordova build

# 2a
# option: run cordova browser app from platforms/browser/www

cordova run browser

# 2b
# option: develop app with webpack and directory platforms/browser/www
# watches app, lib for changes to .rb files
# browser auto reloads page
# servers from www first, platforms/browser/www second
# changes in www (html, css, js) available upon manual page reload

rake webpack:server

# Opal REPL available in lib
# require 'repl' from .rb 

require 'repl'

# run repl directly

REPL.run

# open repl on exception

REPL.rescue do
  raise 'ops!'
end


