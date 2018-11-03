require 'vue'
require 'browser/interval'
require 'pitch'

# TODO: app name
# TODO: app icon
# TODO: visual changes in index.html

# TODO: prevent spurious note changes - wait for same in a row to change note ? give up if erratic ?
# TODO: sensitivity level - manual, and auto ?  average RMS of signal ?

class Tuner < Vue

  INTERVAL = 0.1
  SAMPLES  = 4096
  # SAMPLE_RATE = 44100 ?

  # Strong harmonics of low guitar strings are drowning out root note and causing detection of harmonic note instead of root note. 
  # Even harmonics are same note in higher octave - this kind of okay for a simple tuner (right note, wrong octave)
  # Odd harmonics are different note in higher octave - this is bad! A=110Hz*3=330Hz=E  E=82Hz*3=246Hz=B
  # Attempting to amplify low notes and attenuate high notes...
  # Lowpass filter (biquad)...
  # Cutoff down to 110Hz good for A=110Hz string, still unstable for E=82Hz string, good for E=330Hz string, lost response for A=440Hz
  # Cutoff down to 82Hz good for all strings, lost response for A=440Hz
  # Other filter response curves with more gradual fall off to preserve A=440Hz response ?
  LOWPASS_FILTER_CUTOFF = 82

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
    @analyser.fftSize = SAMPLES * 2
    filter = @audio_context.createBiquadFilter
    filter.type = "lowpass"
    filter.frequency.value = LOWPASS_FILTER_CUTOFF
    filter.connect @analyser 
    media_stream_source = @audio_context.createMediaStreamSource stream
    media_stream_source.connect filter 
    @float32array = `new Float32Array( #{SAMPLES} )` 
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

