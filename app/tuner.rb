require 'vue'
require 'browser/interval'
require 'pitch'

class Tuner < Vue

  INTERVAL = 0.1

  methods :toggle_listening

  data listening: false,
       pitch:     0,
       cents:     0,
       note:      ""

  def toggle_listening
    if listening
      @pitch_loop.abort
      @audio_context.close
      self.listening = false
      return
    end
    start_listening
  end

  def start_listening
    permissions = [
      $$.cordova.plugins.permissions.MODIFY_AUDIO_SETTINGS,
      $$.cordova.plugins.permissions.RECORD_AUDIO
    ]
    $$.cordova.plugins.permissions.requestPermissions(
      permissions, 
      proc do |status|
        if Native(`status`).hasPermission 
          permission_granted
        else
          permission_refused
        end 
      end,
      proc do
        permission_error
      end
    )
  end

  def permission_granted
    puts "Permission granted"
    get_user_media
  end

  def permission_refused
    puts "Permission refused"
    alert( 'Cannot access microphone without permission. Please grant permission.' )
  end

  def permission_error
    puts "Error requesting permission"
    alert( 'Error getting permssion. Try setting permissions, or reinstall app.' )
  end

  def get_user_media
    puts "Tuner#get_user_media"
    $$.navigator.mediaDevices.getUserMedia( { audio: true } ).then do |stream|
      got_stream stream
    end.fail do
      alert('Unable to access microphone.')
    end
  end

  def got_stream stream
    puts "Tuner#got_stream"
    @audio_context = Native `new AudioContext()`
    @analyser = @audio_context.createAnalyser
    @analyser.fftSize = 2048
    # filter above highest guitar note E(6) is 1318.51Hz, A(7) is 1760Hz
    filter = @audio_context.createBiquadFilter
    filter.type = "lowpass"
    filter.frequency.value = 1760
    filter.connect @analyser 
    media_stream_source = @audio_context.createMediaStreamSource stream
    media_stream_source.connect filter 
    @float32array = `new Float32Array( 1024 )` 
    self.listening = true
    @pitch_loop = every(INTERVAL) do
      update_pitch
    end
  end

  def update_pitch
    puts "Tuner#update_pitch"
    @analyser.getFloatTimeDomainData @float32array
    @buffer = Array( @float32array )
    detected_freq = Pitch::Detector.detect3 @buffer, rate: @audio_context.sampleRate
    self.pitch = detected_freq
    unless detected_freq == 0
      detected_note = Pitch.note detected_freq
      self.note  = detected_note.name
      self.cents = detected_note.cents
    end
  end

end

