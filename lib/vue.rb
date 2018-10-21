
class Vue

  attr_accessor :vue

  def initialize element
    config = {
      el: element,
      data: {
      }
    }
    @vue = Native(`new Vue(#{config.to_n})`)
  end

  def self.methods *method_syms

  end

  def self.computed *method_syms

  end

  def data
    raise NotImplementedError
  end

  def mounted
    raise NotImplementedError
  end

end

