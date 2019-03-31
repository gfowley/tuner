require 'vue'

class VueFreqGraph < Vue

  name     'freq-graph'
  template '#freq-graph-template'

  props    :freq, :freq_data, :rate

  computed :points, :grid, :indicator, :viewbox

  FFT_WINDOW = 1.0 # fraction (divisor) of FFT result real bins to display
  FREQ_SCALE = 1   # each bin is FREQ_SCALE svg units (pixels?)
  MAX_AMP    = 255
  
  def points
    fft_to_graph = freq_data.take( freq_data.count / FFT_WINDOW )
    fft_to_graph.each_with_index.map do |amp,i|
      "#{i*FREQ_SCALE},#{MAX_AMP-amp}"
    end.join (' ')
  end

  def grid
    return [] if rate == 0 # avoid Infinity from log2(0)
    # A octaves between lower and upper frequency limits
    lower_freq_limit = 55 # A(1)
    lower_octaves = Math.log2(lower_freq_limit).floor
    upper_octaves = Math.log2(upper_freq_limit).floor
    lines = (upper_octaves-lower_octaves).times.map do |octave|
      {
        freq: ( oct_freq = ( 55 * 2**octave ).to_i ), # avoid strange 55/1 fraction in js conversion?
        x:    ( oct_freq / bin_bandwidth ).round
      }
    end
    # puts "rate: #{rate}"
    # puts "bins: #{freq_data.count}"
    # puts "upper_freq_limit: #{upper_freq_limit}"
    # puts "bin_bandwidth: #{bin_bandwidth}"
    # puts "grid: #{lines.inspect}"
    lines.to_n
  end

  def bin_bandwidth
    upper_freq_limit / ( freq_data.count / FFT_WINDOW )
  end

  def indicator
    return {} if rate == 0 # avoid Infinity from rate/upper_freq_limit
    {
      freq: freq.round,
      x:    ( FREQ_SCALE * ( freq / upper_freq_limit ) ).round
    }.to_n
  end

  def upper_freq_limit
    rate / 2.0 / FFT_WINDOW
  end

  def viewbox
    "0 0 #{viewbox_width} #{viewbox_height}"
  end

  def viewbox_width
    freq_data.count
  end

  def viewbox_height
    MAX_AMP + 1
  end

end 

