
class VueThing < VueComponent
  name     'thing'
  template '#thing-template'
  props    :count
  data     :my_data
  computed :calc, :whoami
  methods  :ruby_object

  def my_data
    {
      other: 1
    }
  end

  def calc
    count * other
  end

  def whoami
    ruby_object
  end

  def ruby_object
    self.inspect
  end

end

