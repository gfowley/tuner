require 'vue'

class VueApp < Vue

  methods :toggle_listening

  data listening: false,
       pitch:     0,
       cents:     0,
       note:      ""

  # TODO: inject tuner dependency instead of global $tuner (methods as procs ?)
  def toggle_listening
    listening ? $tuner.stop_listening : $tuner.start_listening
  end

end

