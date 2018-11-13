require 'vue'

class VueNote < Vue
  name     'note'
  template '#note-template'
  props    :note, :cents
end

# class VueComponentFreqGraph < VueComponent
# end

# class VueComponentTimeGraph < VueComponent
# end


