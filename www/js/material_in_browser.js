// OnsenUI defaults to ios for null platform in browser, force android (material)
if ( !ons.platform.isIOS() && !ons.platform.isAndroid() ) {
  ons.platform.select('android')
}

