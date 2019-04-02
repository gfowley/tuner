require 'native'

class Vue

  include Native

  attr_accessor :vue
  
  def initialize element = nil
   initialize_vue element
  end

  def initialize_vue element
    @config = {
      el:           element,
      data:         resolve_data( self.class.data     ),
      methods:      methods_hash( self.class.methods  ),
      computed:     methods_hash( self.class.computed ),
      mounted:      method(:mounted).to_proc,
      beforeCreate: `function() { #{@vue_this} = this }`,
      created:      method(:created).to_proc
    }
    `new Vue(#{@config.to_n})`
  end

  def self.component component_class
    component_class.register_component
  end

  def self.data data_option=nil
    return @vue_data if data_option.nil?
    @vue_data = data_option
  end

  def self.methods *names
    return @vue_methods if names.empty?
    @vue_methods = names
  end

  def self.computed *names
    return @vue_computed if names.empty?
    @vue_computed = names
  end

  def self.name name=nil
    return @vue_name if name.nil?
    @vue_name = name
  end

  def self.template name=nil
    return @vue_template if name.nil?
    @vue_template = name
  end

  def methods_hash names
    return {} if names.nil?
    names.inject({}) do |mh,name|
      mh[name] = method(name).to_proc
      mh
    end
  end

  def resolve_data data_option
    # symbol or string is a method name, wrap with proc returning native result
    return Proc.new { method(data_option).call.to_n } if data_option.is_a?( Symbol ) || data_option.is_a?( String )
    data_option # otherwise return original object
  end

  def create_accessors_for object
    if ( the_object = @vue[object] )
      properties = `Object.keys(#{the_object.to_n})`
      properties.each { |property| create_accessor object, property }
    end
  end

  def create_accessor object, property
    create_reader object, property
    create_writer object, property
  end

  def create_reader object, property
    self.class.define_method property do
      @vue[object][property]
    end
  end

  def create_writer object, property
    self.class.define_method property+'=' do |arg|
      @vue[object][property] = arg
    end
  end

  def created
    @vue = Native(`#{@vue_this}`)
    create_accessors_for "$data"
  end

  def mounted
  end

end

