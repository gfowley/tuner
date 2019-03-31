require 'browser/interval'
require 'pitch'
require 'vue_app'
# require 'vue_note'
# require 'vue_frequency'
# require 'vue_freq_graph'
require 'vue_thing'

# TODO: app name
# TODO: app icon
# TODO: visual changes in index.html

# TODO: prevent spurious note changes - wait for same in a row to change note ? give up if erratic ?
# TODO: sensitivity level - manual, and auto ?  average RMS of signal ?
# TODO: pitch mode, mean, median in detector ?

class Tuner

  # https://en.wikipedia.org/wiki/Piano_key_frequencies

  LATENCY_HINT = 'interactive'
  FFT_SIZE    = 4096 # 'Real' FFT result bins => 4096/2 = 2048
  # Q: how many samples are needed (how much time) for @audio_context.sampleRate & FFT_SIZE ?
  
  # Strong harmonics of low guitar strings are drowning out root note and causing detection of harmonic note instead of root note. 
  # Even harmonics are same note in higher octave - this is kind of okay for a simple tuner (right note, wrong octave)
  # Odd harmonics are different note in higher octave - this is bad! A=110Hz*3=330Hz=E  E=82Hz*3=246Hz=B
  # Attempting to amplify low notes and attenuate high notes...
  # Lowpass filter (biquad)...
  # Cutoff down to 110Hz good for A=110Hz string, still unstable for E=82Hz string, good for E=330Hz string, lost response for A=440Hz
  # Cutoff down to 82Hz good for all strings, lost response for A=440Hz ?
  # Other filter response curves with more gradual fall off to preserve A=440Hz response ?
  LOWPASS_FILTER_CUTOFF = 82 # TODO: lower cutoff to enable dropped-D detection ?
  # LOWPASS_FILTER_Q = 0  # TODO: smooth down filter corner - test this with guitar

  GAIN = 1.0
  INTERVAL = 0.1

  def initialize
    # @vue_note = VueNote.component
    # @vue_freq = VueFrequency.component
    # @vue_freq_graph = VueFreqGraph.component

    @vue_thing = VueThing.component
    @vue_app   = VueApp.new '#app'
  end

  def stop_listening
    @listening_loop.abort
    @audio_context.close
    @vue.listening = false
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
    get_user_media
  end

  def permission_refused
    alert( 'Cannot access microphone without permission. Please grant permission.' )
  end

  def permission_error
    alert( 'Error getting permssion. Try setting permissions, or reinstall app.' )
  end

  def get_user_media
    $$.navigator.mediaDevices.getUserMedia( { audio: true } ).then do |stream|
      got_stream stream
    end.fail do
      alert('Unable to access microphone.')
    end
  end

  def got_stream stream
    @audio_context = Native `new AudioContext({latencyHint: #{LATENCY_HINT}})`

    @source        = create_stream_source stream
    @gain          = create_gain
    @filter        = create_filter
    @analyser_post = create_analyser
    @analyser_pre  = create_analyser

    @source.connect       @analyser_pre
    @analyser_pre.connect @gain
    @gain.connect         @filter
    @filter.connect       @analyser_post

    @vue.listening = true
    @listening_loop = every(INTERVAL) do
      update_note
      update_freq_graph_pre
      update_freq_graph_post
    end
  end

  def create_stream_source stream
    @audio_context.createMediaStreamSource stream
  end

  def create_gain
    gain = @audio_context.createGain
    gain.gain.value = GAIN 
    gain
  end

  def create_filter
    filter = @audio_context.createBiquadFilter
    filter.type = "lowpass"
    filter.frequency.value = LOWPASS_FILTER_CUTOFF
    filter
  end
 
  def create_analyser
    analyser = @audio_context.createAnalyser
    analyser.fftSize = FFT_SIZE
    analyser
  end

  def update_note
    @float32array ||= `new Float32Array( #{@analyser_post.frequencyBinCount} )` 
    @analyser_post.getFloatTimeDomainData @float32array
    @buffer = Array( @float32array )
    detected_freq = Pitch::Detector.detect3 @buffer, rate: @audio_context.sampleRate
    @vue.freq = detected_freq
    unless detected_freq == 0
      detected_note = Pitch.note detected_freq
      @vue.note  = detected_note.name
      @vue.cents = detected_note.cents
    end
  end

  def update_freq_graph_pre
    uint8array ||= `new Uint8Array( #{@analyser_pre.frequencyBinCount} )` 
    @analyser_pre.getByteFrequencyData uint8array
    @vue.freq_data_pre = Array( uint8array )
    @vue.rate = @audio_context.sampleRate 
  end

  def update_freq_graph_post
    uint8array ||= `new Uint8Array( #{@analyser_post.frequencyBinCount} )` 
    @analyser_post.getByteFrequencyData uint8array
    @vue.freq_data_post = Array( uint8array )
    @vue.rate = @audio_context.sampleRate 
  end

end

