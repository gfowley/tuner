
vue = new Vue({
  el: '#app',
  methods: {
    toggleLiveInput: function(e) {
      if (this.isPlaying) {
        // if (!window.cancelAnimationFrame) {
        //  window.cancelAnimationFrame = window.webkitCancelAnimationFrame;
        //}
        window.cancelAnimationFrame( this.note_af )
        window.cancelAnimationFrame( this.visual_af )
        this.audioContext.close()
        this.isPlaying = false
        return;
      }
      var permission_list = [
        cordova.plugins.permissions.MODIFY_AUDIO_SETTINGS,
        cordova.plugins.permissions.RECORD_AUDIO
      ]
      this.call_with_permission( permission_list, this.getUserMedia, this.permission_refused, this.permission_error );
    },
    call_with_permission: function( permission_list, granted_callback, refused_callback, error_callback ) {
      cordova.plugins.permissions.requestPermissions( permission_list,
        function( status ) {
          if ( status.hasPermission ) {
            // console.log("Permission granted")
            granted_callback()
          } else {
            // console.warn("Permission refused")
            refused_callback()
          }
        },
        function() {
          // console.error("Error requesting permission")
          error_callback()
        }
      )
    },
    permission_refused: function() {
      alert( 'Cannot access microphone without permission. Please grant permission.' )
    },
    permission_error: function() {
      alert( 'Error getting permssion. Try setting permissions, or reinstall app.' )
    },
    getUserMedia: function() {
      var options = { audio: true } // { autoGainControl: false, noiseSuppression: false, echoCancellation: false }
      navigator.getUserMedia = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia
      navigator.getUserMedia( options, this.gotStream, function() { alert('Unable to access microphone.') } )
    },
    gotStream: function(stream) {
      window.AudioContext = window.AudioContext || window.webkitAudioContext;
      this.audioContext = new AudioContext();
      this.mediaStreamSource = this.audioContext.createMediaStreamSource(stream);
      // filter above highest guitar note E(6) is 1318.51Hz, A(7) is 1760Hz
      var filter = this.audioContext.createBiquadFilter();
      filter.type = "lowpass";
      filter.frequency.value = 1760; // high A
      this.analyser = this.audioContext.createAnalyser();
      this.analyser.fftSize = 2048;
      this.mediaStreamSource.connect( filter );
      filter.connect( this.analyser );
      this.isPlaying = true;
      this.updatePitch();
      this.visualize();
    },
    updatePitch: function() {
      this.analyser.getFloatTimeDomainData( this.buf );
      var ac = this.autoCorrelate( this.buf, this.audioContext.sampleRate );
      if (ac == -1) {
        this.pitch  = 0;
        this.detune = 0;
      } else {
        this.pitch       = ac;
        this.note_number = this.noteFromPitch( this.pitch );
        this.detune      = this.centsOffFromPitch( this.pitch, this.note_number );
      }
      this.note_af = window.requestAnimationFrame( this.updatePitch );
      return this.pitch;
    },
    visualize: function() {
      var buffer_divisor = 8;
      var canvas = document.getElementById('visualizer');
      var canvasCtx = canvas.getContext("2d");
      var bufferLength = this.analyser.frequencyBinCount / buffer_divisor;
      var analyser = this.analyser;
      var vc = this;
      var sampleRate = this.audioContext.sampleRate;
      var dataArray = new Uint8Array(bufferLength);
      canvasCtx.clearRect(0, 0, canvas.width, canvas.height);
      var draw = function() {
        vc.visual_af = requestAnimationFrame(draw);
        canvasCtx.fillStyle = 'rgb(0,0,0)';
        canvasCtx.fillRect(0, 0, canvas.width, canvas.height);
        canvasCtx.lineWidth = 1;
        // draw grid
        canvasCtx.font = '1rem sans-serif'
        canvasCtx.textBaseline = 'top'
        canvasCtx.fillStyle = 'rgb(255,128,128)'
        canvasCtx.strokeStyle = 'rgb(255,128,128)'
        var x = 0
        var y = 0
        var freq = 55 // A(1)
        var freq_limit = sampleRate / 2 / buffer_divisor
        var sliceWidth = canvas.width * 1.0 / bufferLength;
        var height_factor = canvas.height/256.0;
        while( freq <= freq_limit ) {
          x = canvas.width * ( freq / freq_limit )
          canvasCtx.beginPath()
          canvasCtx.moveTo( x, 0 )
          canvasCtx.lineTo( x, canvas.height )
          canvasCtx.stroke();
          canvasCtx.fillText( freq, x + 2, 2 )
          freq = freq * 2
        }
        // draw rms level
        // canvasCtx.strokeStyle = 'rgb(128,128,255)'
        // var rms_line = canvas.height - ( vc.rms * height_factor )
        // console.log("RMS line: " + rms_line)
        // canvasCtx.beginPath()
        // canvasCtx.moveTo( 0, rms_line ) 
        // canvasCtx.lineTo( canvas.width, rms_line )
        // canvasCtx.stroke();
        // draw frequency spectrum
        analyser.getByteFrequencyData(dataArray);
        canvasCtx.strokeStyle = 'rgb(255,255,128)';
        canvasCtx.beginPath();
        x = 0;
        canvasCtx.moveTo( x, canvas.height - ( dataArray[0] * height_factor ) );
        for(var i = 1; i < bufferLength; i++) {
          y = dataArray[i] * height_factor 
          canvasCtx.lineTo(x, canvas.height - y);
          x += sliceWidth;
        }
        canvasCtx.stroke();
        // draw detected pitch
        canvasCtx.textBaseline = 'bottom'
        canvasCtx.fillStyle = 'rgb(64,255,64)'
        canvasCtx.strokeStyle = 'rgb(64,255,64)';
        x = canvas.width * ( vc.pitch / freq_limit )
        canvasCtx.beginPath()
        canvasCtx.moveTo( x, 0 )
        canvasCtx.lineTo( x, canvas.height )
        canvasCtx.stroke()
        canvasCtx.fillText( vc.pitch.toFixed(2), x + 2, canvas.height - 2 )
      };
      draw();
    },
    autoCorrelate: function( buf, sampleRate ) {
      var SIZE = buf.length / 2;
      var MAX_SAMPLES = Math.floor(SIZE/2);
      var best_offset = -1;
      var best_correlation = 0;
      var foundGoodCorrelation = false;
      var correlations = new Array(MAX_SAMPLES);
      var sum = 0;
      for (var i=0;i<SIZE;i++) {
        sum += buf[i] * buf[i];
      }
      this.rms = Math.sqrt(sum/SIZE);
      // console.log("RMS: "+this.rms);
      var lastCorrelation=1;
      for (var offset = this.MIN_SAMPLES; offset < MAX_SAMPLES; offset++) {
        var correlation = 0;
        for (var i=0; i<MAX_SAMPLES; i++) {
          correlation += Math.abs((buf[i])-(buf[i+offset]));
        }
        correlation = 1 - (correlation/MAX_SAMPLES);
        correlations[offset] = correlation; // store it, for the tweaking we need to do below.
        if ((correlation>this.GOOD_ENOUGH_CORRELATION) && (correlation > lastCorrelation)) {
          foundGoodCorrelation = true;
          if (correlation > best_correlation) {
            best_correlation = correlation;
            best_offset = offset;
          }
        } else if (foundGoodCorrelation) {
          var shift = (correlations[best_offset+1] - correlations[best_offset-1])/correlations[best_offset];  
          return sampleRate/(best_offset+(8*shift));
        }
        lastCorrelation = correlation;
      }
      if (best_correlation > 0.01) {
        return sampleRate/best_offset;
      }
      return -1;
    },
    noteFromPitch: function( frequency ) {
      var noteNum = 12 * (Math.log( frequency / 440 )/Math.log(2) );
      return Math.round( noteNum ) + 69;
    },
    frequencyFromNoteNumber: function( note ) {
      return 440 * Math.pow(2,(note-69)/12);
    },
    centsOffFromPitch: function( frequency, note ) {
      return Math.floor( 1200 * Math.log( frequency / this.frequencyFromNoteNumber( note ))/Math.log(2) );
    }
  },
  data: function() {
    return {
      deviceready: false,
      audioContext: null,
      isPlaying: false,
      sourceNode: null,
      analyser: null,
      mediaStreamSource: null,
      note_af: null,
      visual_af: null,
      buf: new Float32Array( 1024 ),
      NOTES: ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"],
      MIN_SAMPLES: 0, 
      GOOD_ENOUGH_CORRELATION: 0.9,
      pitch: 0,
      detune: 0,
      note_number: null,
      rms: 0
    }
  },
  computed: {
    note: function() {
      return this.pitch == 0 ? '--' : this.NOTES[this.note_number%12];
    }
  },
  mounted: function() {
    var canvas = document.getElementById('visualizer')
    canvas.width  = window.innerWidth  * 0.80
    canvas.height = window.innerHeight * 0.20 
  }
});

