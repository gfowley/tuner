require 'native'

# TODO: watchers and other method types

class Vue

  include Native

  attr_accessor :native
  
  def initialize element = nil, component = false
    component ? initialize_component : initialize_app( element )
  end

  def initialize_app element
    @config = {
      el:           element,
      data:         self.class.data,
      methods:      methods_hash( self.class.methods  ),
      computed:     methods_hash( self.class.computed ),
      mounted:      method(:mounted).to_proc,
      beforeCreate: `function() { #{@vue} = this }`,
      created:      method(:created).to_proc
    }
    Native(`tuner = new Vue(#{@config.to_n})`)
  end

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

  def self.data pairs=nil
    # TODO: also handle data as function
    return @vue_data if pairs.nil?
    @vue_data = pairs
    pairs.each { |name,_| my_native_accessor name }
  end

  def self.my_native_accessor name
    my_native_reader name
    my_native_writer name
  end

  def self.my_native_reader name
    define_method name do
      @native[name]
    end
  end

  def self.my_native_writer name
    define_method name+'=' do |arg|
      @native[name] = arg
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

  def self.props *props
    # TODO: also handle a hash of { name: validation, ... }
    return @vue_props if props.empty?
    @vue_props = props
    # TODO: ruby native accessor for component props: JS... tuner.$children[0].$children[2]._props.note="Q"
    props.each { |prop| my_native_accessor prop }
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
  end

  def mounted
    # may be provided by subclass
  end

end

