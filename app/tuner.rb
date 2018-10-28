require 'vue'

class Tuner < Vue

  NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

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
      # JS: window.cancelAnimationFrame( this.note_af )
      # JS: window.cancelAnimationFrame( this.visual_af )
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
    update_pitch
    # JS: this.visualize();
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
    # JS: this.note_af = window.requestAnimationFrame( this.updatePitch );
  end

  def auto_correlate buffer, rate
    puts "Tuner#auto_correlate"
    1234
  end

  def note_number_from_pitch frequency 
    puts "Tuner#note_number_from_pitch"
    ( 12 * Math.log( frequency / 440.0 ) / Math.log(2) ).round + 69
  end

  def detune_from_pitch frequency
    puts "Tuner#detune_from_pitch"
    ( 1200 * Math.log( frequency / ( 440 * ( 2 ** ((note_number-69)/12) ) ) ) / Math.log(2) ).floor
  end

  # def visualize
  #   %x{
  #   var buffer_divisor = 8;
  #   var canvas = document.getElementById('visualizer');
  #   var canvasCtx = canvas.getContext("2d");
  #   var bufferLength = this.analyser.frequencyBinCount / buffer_divisor;
  #   var analyser = this.analyser;
  #   var vc = this;
  #   var sampleRate = this.audioContext.sampleRate;
  #   var dataArray = new Uint8Array(bufferLength);
  #   canvasCtx.clearRect(0, 0, canvas.width, canvas.height);
  #   var draw = function() {
  #     vc.visual_af = requestAnimationFrame(draw);
  #     canvasCtx.fillStyle = 'rgb(0,0,0)';
  #     canvasCtx.fillRect(0, 0, canvas.width, canvas.height);
  #     canvasCtx.lineWidth = 1;
  #     // draw grid
  #     canvasCtx.font = '1rem sans-serif'
  #     canvasCtx.textBaseline = 'top'
  #     canvasCtx.fillStyle = 'rgb(255,128,128)'
  #     canvasCtx.strokeStyle = 'rgb(255,128,128)'
  #     var x = 0
  #     var y = 0
  #     var freq = 55 // A(1)
  #     var freq_limit = sampleRate / 2 / buffer_divisor
  #     var sliceWidth = canvas.width * 1.0 / bufferLength;
  #     var height_factor = canvas.height/256.0;
  #     while( freq <= freq_limit ) {
  #       x = canvas.width * ( freq / freq_limit )
  #       canvasCtx.beginPath()
  #       canvasCtx.moveTo( x, 0 )
  #       canvasCtx.lineTo( x, canvas.height )
  #       canvasCtx.stroke();
  #       canvasCtx.fillText( freq, x + 2, 2 )
  #       freq = freq * 2
  #     }
  #     // draw rms level
  #     // canvasCtx.strokeStyle = 'rgb(128,128,255)'
  #     // var rms_line = canvas.height - ( vc.rms * height_factor )
  #     // console.log("RMS line: " + rms_line)
  #     // canvasCtx.beginPath()
  #     // canvasCtx.moveTo( 0, rms_line ) 
  #     // canvasCtx.lineTo( canvas.width, rms_line )
  #     // canvasCtx.stroke();
  #     // draw frequency spectrum
  #     analyser.getByteFrequencyData(dataArray);
  #     canvasCtx.strokeStyle = 'rgb(255,255,128)';
  #     canvasCtx.beginPath();
  #     x = 0;
  #     canvasCtx.moveTo( x, canvas.height - ( dataArray[0] * height_factor ) );
  #     for(var i = 1; i < bufferLength; i++) {
  #       y = dataArray[i] * height_factor 
  #       canvasCtx.lineTo(x, canvas.height - y);
  #       x += sliceWidth;
  #     }
  #     canvasCtx.stroke();
  #     // draw detected pitch
  #     canvasCtx.textBaseline = 'bottom'
  #     canvasCtx.fillStyle = 'rgb(64,255,64)'
  #     canvasCtx.strokeStyle = 'rgb(64,255,64)';
  #     x = canvas.width * ( vc.pitch / freq_limit )
  #     canvasCtx.beginPath()
  #     canvasCtx.moveTo( x, 0 )
  #     canvasCtx.lineTo( x, canvas.height )
  #     canvasCtx.stroke()
  #     canvasCtx.fillText( vc.pitch.toFixed(2), x + 2, canvas.height - 2 )
  #   };
  #   draw();
  #   }
  # end
      
  # def autoCorrelate buf, sampleRate 
  #   %x{
  #   var SIZE = buf.length / 2;
  #   var MAX_SAMPLES = Math.floor(SIZE/2);
  #   var best_offset = -1;
  #   var best_correlation = 0;
  #   var foundGoodCorrelation = false;
  #   var correlations = new Array(MAX_SAMPLES);
  #   var sum = 0;
  #   for (var i=0;i<SIZE;i++) {
  #     sum += buf[i] * buf[i];
  #   }
  #   this.rms = Math.sqrt(sum/SIZE);
  #   // console.log("RMS: "+this.rms);
  #   var lastCorrelation=1;
  #   for (var offset = this.MIN_SAMPLES; offset < MAX_SAMPLES; offset++) {
  #     var correlation = 0;
  #     for (var i=0; i<MAX_SAMPLES; i++) {
  #       correlation += Math.abs((buf[i])-(buf[i+offset]));
  #     }
  #     correlation = 1 - (correlation/MAX_SAMPLES);
  #     correlations[offset] = correlation; // store it, for the tweaking we need to do below.
  #     if ((correlation>this.GOOD_ENOUGH_CORRELATION) && (correlation > lastCorrelation)) {
  #       foundGoodCorrelation = true;
  #       if (correlation > best_correlation) {
  #         best_correlation = correlation;
  #         best_offset = offset;
  #       }
  #     } else if (foundGoodCorrelation) {
  #       var shift = (correlations[best_offset+1] - correlations[best_offset-1])/correlations[best_offset];  
  #       return sampleRate/(best_offset+(8*shift));
  #     }
  #     lastCorrelation = correlation;
  #   }
  #   if (best_correlation > 0.01) {
  #     return sampleRate/best_offset;
  #   }
  #   return -1;
  #   }
  # end

  # def noteFromPitch frequency 
  #   %x{
  #   var noteNum = 12 * (Math.log( frequency / 440 )/Math.log(2) );
  #   return Math.round( noteNum ) + 69;
  #   }
  # end
  
  # def frequencyFromNoteNumber note 
  #   %x{
  #   return 440 * Math.pow(2,(note-69)/12);
  #   }
  # end

  # def centsOffFromPitch frequency, note 
  #   %x{
  #   return Math.floor( 1200 * Math.log( frequency / this.frequencyFromNoteNumber( note ))/Math.log(2) );
  #   }
  # end
  
end



