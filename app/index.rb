require 'opal' 
require 'opal/version' 
require 'browser'
require 'native'
require 'repl'
require 'tuner'

puts "Opal #{Opal::VERSION}"

$document.ready do
  $document.on( :deviceready ) { |event| on_deviceready event }
end

def on_deviceready event
  puts 'cordova:deviceready'
  create_tuner
  # REPL.run $tuner
  show_app
  bind_cordova_events
end

def create_tuner
  $tuner = Tuner.new 
end

def show_app
  # app element is initially invisible to hide mess until onsen makes it pretty
  # cordova splashscreen would also work
  $document['app'].attributes[:class] = "visible"
end

def bind_cordova_events
  # https://cordova.apache.org/docs/en/latest/cordova/events/events.html
  Native(`document`).addEventListener('pause'           ) { on_pause            }
  Native(`document`).addEventListener('resume'          ) { on_resume           }
  Native(`document`).addEventListener('backbutton'      ) { on_backbutton       }
  Native(`document`).addEventListener('menubutton'      ) { on_menubutton       }
  Native(`document`).addEventListener('searchbutton'    ) { on_searchbutton     }
  Native(`document`).addEventListener('startcallbutton' ) { on_startcallbutton  }
  Native(`document`).addEventListener('endcallbutton'   ) { on_endcallbutton    }
  Native(`document`).addEventListener('volumeupbutton'  ) { on_volumeupbutton   }
  Native(`document`).addEventListener('volumedownbutton') { on_volumedownbutton }
  # using Native(...) instead of $document.on(...) because...
  # these throw "Argument Error" "nil isn't native"...  something about cordova events ?
  #   $document.on( :pause ) { on_pause }
  #   $document.on( :pause ) { |event| on_event event }
  # this throws undefined method 'name' for nil... nil event passed to block ?
  #   Native(`document`).addEventListener('pause') { |event| on_event event }
  # try wrapping the cordova event in an Opal Event wrapper ?
end

def on_pause            ; puts 'cordova:pause'            ; end
def on_resume           ; puts 'cordova:resume'           ; end
def on_backbutton       ; puts 'cordova:backbutton'       ; end
def on_menubutton       ; puts 'cordova:menubutton'       ; end
def on_searchbutton     ; puts 'cordova:searchbutton'     ; end
def on_startcallbutton  ; puts 'cordova:startcallbutton'  ; end
def on_endcallbutton    ; puts 'cordova:endcallbutton'    ; end
def on_volumeupbutton   ; puts 'cordova:volumeupbutton'   ; end
def on_volumedownbutton ; puts 'cordova:volumedownbutton' ; end

