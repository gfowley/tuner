require 'vue'

class VueComponentNote < Vue
 
  name 'just-a-note'
  
  template '#note-template'

  props  :note, :cents

end

# class VueComponentFreqGraph < VueComponent
# end

# class VueComponentTimeGraph < VueComponent
# end


