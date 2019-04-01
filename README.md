# Development

## Build
Build app from directory ```www``` to ```platforms/browser/www```.  
```
cordova build
```
Cordova ```build``` runs ```cordova prepare``` and ```compile```.
Cordova hook ```before_prepare``` (```scripts/before_prepare.js```) runs ```rake webpack:build``` to create bundle in directory ```www/js```.

## Run in browser (cordova)
Run browser app via ```cordova``` from ```platforms/browser/www```.
```
cordova run browser
```

## Run in browser (webpack-dev-server)
Run browser app via ```webpack-dev-server``` from ```platforms/browser/www``` on ```http://localhost:8000```.
```
rake webpack:server
```
Auto reloads page on changes to ```.rb``` files in ```app```, ```lib```. 
Serves from ```www``` first, ```platforms/browser/www``` second.
Changes in ```www``` (html, css, js) require manual page reload.

# Opal stuff... 

## Simple REPL
Simple Opal REPL in ```lib/repl.rb```. Require from ```.rb```. 
```
require 'repl'
```
Run REPL directly.
```
REPL.run
```
Open REPL on exception.
```
REPL.rescue do
  raise 'oops!'
end
```

## Vue.js Wrapper
Opal wrapper for Vue.js in ```lib/vue.rb``` and ```lib/vue_component.rb```.

## Webpack
Configuration file.
```
webpack.config.js
```
Opal app entrypoint is ```app/index.rb```.
Configures webpack-dev-server to watch ```.rb``` files in ```app/``` and ```lib/``` directories.

Loader file.
```
iqeo_opal_loader.js
```
Runs ```rake opal:webpack_build``` to build ```.rb``` files in ```app/``` and ```lib/``` directories.
