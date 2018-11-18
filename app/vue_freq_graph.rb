require 'vue'

class VueFreqGraph < Vue

  name     'freq-graph'
  template '#freq-graph-template'

  props    :freq_data, :rate

  computed :points, :grid

  GRAPH_FFT_WINDOW = 8 # fraction (divisor) of FFT to display
  GRAPH_WIDTH = 1024 # TODO: what should this be (calculate from FFT size ?)

  def points
    fft_to_graph = freq_data.take( freq_data.count / GRAPH_FFT_WINDOW )
    fft_to_graph.each_with_index.map do |amp,i|
      "#{i},#{255-amp}" 
    end.join (' ')
  end

  def grid
    return [] if rate == 0 # avoid -Infinity from log2(0)
    # mark octaves between lower and upper frequency limits
    lower_freq_limit = 55 # A(1)
    upper_freq_limit = rate / 2 / GRAPH_FFT_WINDOW
    lower_octaves = Math.log2(lower_freq_limit).floor
    upper_octaves = Math.log2(upper_freq_limit).floor
    (upper_octaves-lower_octaves).times.map do |octave|
      {
        freq: ( freq = ( 55 * 2**octave ).to_i ), # avoid strange 55/1 fraction in js conversion?
        x:    ( GRAPH_WIDTH * ( freq / upper_freq_limit ) ).round
      }.to_n
    end
  end

end 

