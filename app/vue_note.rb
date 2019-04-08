
class VueNote < VueComponent
  name     'note'
  template '#note-template'
  props    :note, :cents
end

