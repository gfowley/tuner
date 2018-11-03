require 'native'

#TODO: watchers and other method types
#TODO: component

class Vue

  include Native

  attr_accessor :native
  
  def initialize element
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

  def created
    @native = Native(`#{@vue}`)
  end

  def self.data pairs=nil
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

  def methods_hash names
    return {} if names.nil?
    names.inject({}) do |mh,name|
      mh[name] = method(name).to_proc
      mh
    end
  end

  def mounted
    # provided by subclass
  end

end

