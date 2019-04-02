
class VueComponent < Vue

  def initialize vue_this
    # currently only works when called from beforeCreate hook when Vue creates an instance of a registered component
    @vue_this = vue_this # needed by Vue#created hook
    # options are a little different than when passing them to Vue.component 
    js_options = vue_this.JS[:$options]
    js_options.JS[:data    ] = resolve_data( self.class.data     ).to_n
    js_options.JS[:methods ] = methods_hash( self.class.methods  ).to_n
    js_options.JS[:computed] = methods_hash( self.class.computed ).to_n
    js_options.JS[:created ] = [ method(:created).to_proc ]  # now needs an Array
    js_options.JS[:mounted ] = [ method(:mounted).to_proc ]  # now needs an Array
  end

  def self.register_component
    # Vue dynamically creates JS Vue components as needed...
    # beforeCreate hook will create a corresponding ruby VueComponent instance and pass JS 'this'
    # other options will be set in the context of this ruby VueComponent instance
    # props need to be specified in initial options (not in beforeCreate hook) to work
    options = {
      template:     self.template,
      props:        self.props,
      beforeCreate: `function() { Opal[#{self.to_s}].$new( this ) }`
    }
    `Vue.component(#{self.name},#{options.to_n})`
  end

  def self.props *props
    # TODO: also handle a hash of { name: validation, ... }
    return @vue_props if props.empty?
    @vue_props = props
  end

  def created
    super
    create_accessors_for "$props"
  end

end

