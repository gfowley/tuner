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
    {
      listening:      false,
      note:           "",
      cents:          0,
      freq:           0,
      rate:           0,
      freq_data_pre:  [],
      freq_data_post: [],
      count1:         3,
      count2:         5
    }
  end

end

