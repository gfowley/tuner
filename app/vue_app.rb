require 'vue'

class VueApp < Vue

  methods :toggle_listening

  data :test_data_method
  # data listening: false,
  #      pitch:     0,
  #      cents:     0,
  #      note:      ""

  # TODO: inject tuner dependency instead of global $tuner (methods as procs ?)
  def toggle_listening
    listening ? $tuner.stop_listening : $tuner.start_listening
  end

  def test_data_method
    puts "VueApp#test_data_method"
    {
      listening: false,
      pitch:     0,
      cents:     0,
      note:      ""
    }.to_n
  end

end

