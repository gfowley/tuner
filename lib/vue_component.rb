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

# TODO: consider making data = ruby instance variables ? with public accessors ? 

class VueComponent

  include Native

  attr_accessor :native
  
  # TODO: js vue creates components as needed in templates
  #       ruby component will only track one of those
  #       first one ? last one ? 
  #       will created hook and data method be called for each new js component ?
  #       is it useful to make components + accessors available to dev ? js vue does not!

  # FIX: for multiple of same components props are separate
  #      but computed methods execute in the same (last) ruby object instance
  #      try making component a class, and create new instances when component is created by Vue ?
  
  # TRY: component not creating a new instance
  #      Vue.component registered js options object with special beforeCreate hook
  #      hook creates new ruby instance and populates js options referencing this ruby instance
  #      (instead of the single ruby instance self.component used to create)
  #      js 'this' is set to the js vue instance calling beforeCreate !!!
  #      may be useful to move ruby '@native = ..' from create into beforeCreate ?
  #      access js options object from js 'this' in beforeCreate hook ???
  #      ...to set options methods,computed, etc.. context to new ruby instance

  def self.component
    puts class_name = self.to_s
    # Vue dynamically creates JS Vue components...
    # beforeCreate hook will create a corresponding ruby VueComponent instance and pass JS 'this'
    # other options will be set in the context of this ruby VueComponent instance
    options = {
      template:     self.template,
      props:        self.props,
      beforeCreate: `function() { Opal[#{class_name}].$new( this ) }`
    }
    Native(`Vue.component(#{self.name},#{options.to_n})`)
  end

  def initialize js_this
    puts "VueComponent#initialize"
    `console.log(#{js_this})`
    @vue = js_this  # needed later in created hook
    # options that are methods are converted to procs with closures in this ruby VueComponent instance
    js_options = js_this.JS[:$options]
    js_options.JS[:data    ] = resolve_data( self.class.data     ).to_n
    js_options.JS[:methods ] = methods_hash( self.class.methods  ).to_n
    js_options.JS[:computed] = methods_hash( self.class.computed ).to_n
    js_options.JS[:created ] = [ method(:created).to_proc ]  
    js_options.JS[:mounted ] = [ method(:mounted).to_proc ]
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
    puts "VueComponent#created"
    `console.log(this)`
    @native = Native(`#{@vue}`)
    create_data_accessors
    create_prop_accessors
  end

  def mounted
    puts "VueComponent#mounted"
    `console.log(this)`
    # may be provided by subclass
  end

end

