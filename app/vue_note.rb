require 'vue'

class VueNote < Vue
  name     'note'
  template '#note-template'
  props    :note, :cents
end

