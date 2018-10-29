require 'vue'
require 'browser/interval'

class Tuner < Vue

  NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
  INTERVAL = 0.1

  methods :toggle_listening

  computed :note

  data listening:   false,
       pitch:       0,
       detune:      0,
       note_number: 0

  def note
    pitch == 0 ? '--' : NOTES[note_number%12];
  end

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
    options = { audio: true } # { autoGainControl: false, noiseSuppression: false, echoCancellation: false }
    # TODO: make this browser portable (may not work on Android!)
    # JS: navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia
    $$.navigator.mozGetUserMedia( options, method(:got_stream).to_proc ) do
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
    @buffer = `new Float32Array( 1024 )`
    self.listening = true
    @pitch_loop = every(INTERVAL) do
      update_pitch
    end
  end

  def update_pitch
    puts "Tuner#update_pitch"
    @analyser.getFloatTimeDomainData @buffer
    ac = auto_correlate @buffer, @audio_context.sampleRate
    if ac == -1 
      self.pitch  = 0
      self.detune = 0
    else 
      self.pitch       = ac
      self.note_number = note_number_from_pitch pitch
      self.detune      = detune_from_pitch pitch
    end
  end

  FAKE_PITCH = 1234
  def auto_correlate buffer, rate
    puts "Tuner#auto_correlate"
    @current_pitch ||= FAKE_PITCH
    @current_pitch = @current_pitch * 1.005
  end

  def note_number_from_pitch frequency 
    puts "Tuner#note_number_from_pitch"
    ( 12 * Math.log( frequency / 440.0 ) / Math.log(2) ).round + 69
  end

  def detune_from_pitch frequency
    puts "Tuner#detune_from_pitch"
    ( 1200 * Math.log( frequency / ( 440 * ( 2 ** ((note_number-69)/12) ) ) ) / Math.log(2) ).floor
  end

end

