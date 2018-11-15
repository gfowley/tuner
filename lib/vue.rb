require 'native'

# https://vuejs.org/v2/api/
# https://vuejs.org/v2/api/#Options-Data
# TODO: watch, propsData
# https://vuejs.org/v2/api/#Options-DOM
# https://vuejs.org/v2/api/#Options-Lifecycle-Hooks
# TODO: also accept a symbol instead of defining method
# TODO: also wrap beforeCreate and created methods
# https://vuejs.org/v2/api/#Options-Assets
# https://vuejs.org/v2/api/#Options-Composition
# https://vuejs.org/v2/api/#Options-Misc

class Vue

  include Native

  attr_accessor :native
  
  def initialize element = nil, component = false
    component ? initialize_component : initialize_app( element )
  end

  def initialize_app element
    @config = {
      el:           element,
      data:         resolve_data( self.class.data     ),
      methods:      methods_hash( self.class.methods  ),
      computed:     methods_hash( self.class.computed ),
      mounted:      method(:mounted).to_proc,
      beforeCreate: `function() { #{@vue} = this }`,
      created:      method(:created).to_proc
    }
    Native(`tuner = new Vue(#{@config.to_n})`)
  end

  # TODO: js vue creates components as needed in templates
  #       ruby component will only track one of those
  #       first one ? last one ? 
  #       will created hook and data method be called for each new js component ?
  #       is it useful to make components + accessors available to dev ? js vue does not!
  def initialize_component
    @config = {
      template:     self.class.template,
      props:        self.class.props,
      methods:      methods_hash( self.class.methods  ),
      computed:     methods_hash( self.class.computed ),
      mounted:      method(:mounted).to_proc,
      beforeCreate: `function() { #{@vue} = this }`,
      created:      method(:created).to_proc
    }
    Native(`comp = Vue.component(#{self.class.name},#{@config.to_n})`)
  end

  def self.component
    new nil, true
  end

  def self.data data_option=nil
    return @vue_data if data_option.nil?
    @vue_data = data_option
  end

  def resolve_data data_option
    # symbol or string is a method name, wrap with proc returning native result
    return Proc.new { method(data_option).call.to_n } if data_option.is_a?( Symbol ) || data_option.is_a?( String )
    data_option # otherwise return original object
  end

  def create_data_accessors
    names = `Object.keys(#{@native['$data'].to_n})`
    names.each { |name| native_data_accessor name }
  end

  def native_data_accessor name
    native_data_reader name
    native_data_writer name
  end

  def native_data_reader name
    self.class.define_method name do
      @native['$data'][name]
    end
  end

  def native_data_writer name
    self.class.define_method name+'=' do |arg|
      @native['$data'][name] = arg
    end
  end

  def self.props *props
    # TODO: also handle a hash of { name: validation, ... }
    return @vue_props if props.empty?
    @vue_props = props
  end

  def create_prop_accessors
    if ( props = @native['$props'] )
      names = `Object.keys(#{props.to_n})`
      names.each { |name| native_prop_accessor name }
    end
  end

  def native_prop_accessor name
    native_prop_reader name
    native_prop_writer name
  end

  def native_prop_reader name
    self.class.define_method name do
      @native['$props'][name]
    end
  end

  def native_prop_writer name
    # Vue will warn about changing a prop...
    self.class.define_method name+'=' do |arg|
      @native['$props'][name] = arg
    end
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

  def created
    @native = Native(`#{@vue}`)
    create_data_accessors
    create_prop_accessors
  end

  def mounted
    # may be provided by subclass
  end

end

