require 'opal-parser'
require 'browser/effects'

class REPL

  def self.run *args
    REPL.start *args
    REPL.open
    @singelton
  end

  def self.start context         = "main",
                 keep_local_vars = true,
                 input_id        = 'repl-input',
                 output_id       = 'repl-output',
                 prompt_id       = 'repl-prompt',
                 console_id      = 'repl-console'
    REPL.add_to_page
    @input_id   = input_id
    @console_id = console_id
    @singleton ||= self.new context, keep_local_vars, input_id, output_id, prompt_id
  end

  def self.started?
    !!@singleton
  end

  def self.stop
    REPL.close
    @singleton.detach_input_event_handler
    @singleton = nil
  end

  def self.stopped?
    !started?
  end

  def self.open
    raise "REPL not started" unless started?
    $document[@console_id].attributes[:class] = "repl-open"
    $document[@input_id].scroll.to!
    $document[@input_id].focus
  end

  def self.open?
    return false unless started?
    $document[@console_id].attributes[:class] == "repl-open"
  end

  def self.close
    $document[@console_id].attributes[:class] = "repl-close"
  end

  def self.closed?
    !open?
  end

  def self.rescue context='main', &block
    begin
      yield
    rescue
      @rescue = true
      REPL.start context
      REPL.open
    end
  end

  def self.rescue?
    !!@rescue
  end

  def self.remove_from_page
    if ( e = $document['repl-container'] )
      e.remove
    end
  end

  def self.add_to_page container=$document.body
    REPL.remove_from_page
    e = $document.create_element 'div'
    e.id = 'repl-container'
    e.inner_html = '
<style type="text/css" media="all">
  #repl-container {
    width: 100%;
    position: fixed;
    bottom: 0;
  }
  #repl-button {
    margin: 0.5rem; 
  }
  #repl-console {
    width: 100%;
    grid-template-columns: auto 1fr;
  }
  #repl-output {
    grid-row: 1;
    grid-column: 1 / span 2;
    background-color: #555;
    color:            #ccc;
    white-space: pre-wrap;
    word-break: break-all;
  }
  #repl-prompt {
    grid-row: 2;
    grid-column: 1;
    background-color: #666;
    color:            #eee;
    white-space: pre;
  }
  #repl-input {
    grid-row: 2;
    grid-column: 2;
    background-color: #666;
    color:            #eee;
    caret-color:      #fff;
    border-style: none;
    padding: 0;
    white-space: pre-wrap;
  }
  .repl-open {
    display: grid;
  }
  .repl-close {
    display: none;
  }
  .repl-part {
    font-family:      monospace;
    font-style:       normal;
    font-weight:      normal;
    font-size:        16pt;
    margin: 0;
  }
</style>
<button id="repl-button">Toggle REPL</button>
<div id="repl-console" class="repl-close">
  <div id="repl-output" class="repl-part"></div>
  <div id="repl-prompt" class="repl-part">&nbsp;&gt;&nbsp;</div>
  <div id="repl-input"  class="repl-part" contenteditable="true"></div>
</div>'
    e.append_to container
    $document['repl-button'].on(:click) do
      REPL.start unless REPL.started?
      REPL.open? ? REPL.close : REPL.open
    end
  end

  def initialize context         = "main",
                 keep_local_vars = true,
                 input_id        = 'repl-input',
                 output_id       = 'repl-output',
                 prompt_id       = 'repl-prompt'
    @input_id  = input_id
    @input     = $document[input_id]
    @output_id = output_id
    @output    = $document[output_id]
    @prompt_id = prompt_id
    @prompt    = $document[prompt_id]
    capture_console
    @input.scroll.to!
    @input.focus
    @history = []
    @history_index = 0
    disable_multiline
    set_context context
    # create JS Opal.irb_vars to preserve repl local variables across commands
    Native(`Opal.irb_vars = {}`) if keep_local_vars
    attach_input_event_handler
  end

  def attach_input_event_handler
    @input.on( :keypress ) do |event|
      if event.ctrl?
        case event.key
        when "m"
          enable_multiline
        when "ArrowUp"
          prev_history
        when "ArrowDown"
          next_history
        when "Enter"
          if @multiline
            @saved_input = nil
            input_command
            disable_multiline
            event.prevent
          end
        end
      else
        case event.key
        when "Enter"
          unless @multiline
            @saved_input = nil
            input_command
            event.prevent
          end
        end
      end
    end
    # actual character input
    @input.on( :input ) do |event|
      @saved_input = nil
    end
  end

  def prev_history
    unless @history.empty?
      @saved_input ||= contenteditable_text
      @history_index = [ 0, @history_index - 1 ].max
      set_input_from_history @history_index
    end
  end

  def next_history
    unless @history.empty?
      @saved_input ||= contenteditable_text
      @history_index = [ @history.count, @history_index + 1 ].min
      if @history_index < @history.count 
        set_input_from_history @history_index
      else
        set_input @saved_input
      end
    end
  end

  def set_input_from_history index
    cmd = @history[index]
    set_input cmd
  end

  def set_input cmd
    @input.inner_text = cmd
    if cmd.index "\n"
      enable_multiline
    else
      disable_multiline
    end
    @input.scroll.to!
  end

  def send_key_to_input
    # TODO: history should move cursor to end of input, create event (keypress?) and trigger #repl-input with it
    # something like this...
    `
      var e = new Event("keypress");  // may need to trigger keydown ? or whole sequence of keyboard events ?
      e.key="X";
      e.keyCode=e.key.charCodeAt(0);
      e.which=e.keyCode;
      e.altKey=false;
      e.ctrlKey=true;
      e.shiftKey=false;
      e.metaKey=false;
      e.bubbles=true;
      document.getElementById('repl-input').dispatchEvent(e);
    `
  end

  def add_history cmd
    unless cmd == @history.last
      @history << cmd
      @history_index = @history.count
    end
  end

  def detach_input_event_handler
    @input.off :keypress
  end

  def enable_multiline
    @multiline = true    
    update_prompt
  end

  def disable_multiline
    @multiline = false    
    update_prompt
  end

  # def add_newline_to_input
  #   @input.inner_text = @input.inner_text + "\n"
  # end

  def contenteditable_text
    divs = @input.css('div').to_ary
    if divs.empty?
      @input.inner_text
    else
      divs.map { |div| div.inner_text }.join("\n")
    end
  end

  def clear_input
    @input.inner_text = ""
  end

  def input_command
    # context.instance_eval( cmd ) provides an object 'self' context but no access to local variables
    #   of the method it is called from! - not much use as a debugger !
    # Opal does not have a local_variables method (that is a method of binding in ruby)
    # Can JavaScript bind() function binding help ???
    cmd = contenteditable_text
    @output.content += format_indent prompt_text, cmd
    unless cmd.nil? || cmd.empty?
      add_history cmd
      clear_input
      case
      when cmd[0] == '.'
        eval_repl cmd[1..-1]
      else
        eval_ruby cmd
      end
    end
    @input.scroll.to!
    @input.focus 
  end

  def eval_ruby cmd
    begin
      result = @context == "main" ? repl_eval( cmd, false ) : @context.repl_eval( cmd ) 
      @output.content += "=> #{result.inspect}\n"
      result
    rescue Exception => e
      @output.content += "#{e.class}: #{e.message}\n"
      e
    end
  end

  COMMANDS = %w( help history context close exit )

  def eval_repl cmd
    cmd_name = cmd.split.first
    if COMMANDS.include? cmd_name
      send "cmd_#{cmd_name}", cmd[cmd_name.length..-1].strip
    else
      puts "Error: Unknown console command '#{cmd_name}'. Enter '.help' to see all console commands."
    end
  end

  def cmd_help arg
    @output.content += ".close   : Close console\n"
    @output.content += ".exit    : Exit and close console\n"
    @output.content += ".help    : This list of commands\n"
    @output.content += ".history : Command history\n"
    @output.content += ".context : Execution context (self)\n"
    @output.content += "Enter '.help command' for command-specific help\n"
  end

  def cmd_exit
    REPL.stop
  end

  def cmd_close
    REPL.close
  end

  def cmd_history arg
    if arg.nil? || arg.empty?
      @history.each_with_index do |cmd,i|
        @output.content += format_indent "#{i}: ", cmd
      end
      return
    end
    unless arg =~ /^\d+$/
      @output.content += "Invalid number #{arg}\n"
      return
    end
    index = arg.to_i
    unless ( index.between? 0, @history.count - 1 )
      @output.content += "No history at index #{index}\n"
      return
    end
    set_input_from_history index
  end

  def cmd_context arg
    if arg.nil? || arg.empty?
      @output.content += "No context provided\n"
      return
    end
    new_context = ( ( arg == "main" ) ? "main" : eval_ruby( arg ) ) 
    set_context new_context unless new_context.is_a? Exception
  end

  def format_indent prefix, cmd
    lines = cmd.lines.map do |line|
      "#{' '*prefix.length}#{line.chomp}\n"
    end
    lines[0] = "#{prefix}#{cmd.lines.first.chomp}\n"
    lines.join
  end

  def prompt_text
    "(#{@context_name}) #{@multiline ? '#' : '>'} "
  end

  def context_name
    return "main" if @context == "main"
    @context.repl_eval( "self.to_s" )
  end

  def set_context context
    @context = context
    @context_name = context_name
    update_prompt
  end

  def update_prompt
    @prompt.text = prompt_text
  end

  def capture_console
    capture_console_log
    capture_console_warn
    capture_console_error
  end

  def capture_console_log
    # TODO: this should work with %x strings for multiline javascript and interpolate 'repl-output'
    `console_log_original = console.log;`
    `console.log = function(text) { console_log_original(text); document.getElementById('repl-output').textContent += text; };`
  end

  def capture_console_warn
    # TODO: this should work with %x strings for multiline javascript and interpolate 'repl-output'
    `console_warn_original = console.warn;`
    `console.warn = function(text) { console_warn_original(text); document.getElementById('repl-output').textContent += text; };`
  end

  # FIX: does not capture exception text, need to rescue exception ?
  def capture_console_error
    # TODO: this should work with %x strings for multiline javascript and interpolate 'repl-output'
    `console_error_original = console.error;`
    `console.error = function(text) { console_error_original(text); document.getElementById('repl-output').textContent += text; };`
  end

end

class BasicObject

  # adapted from #BasicObject#instance_eval at...
  # https://github.com/opal/opal/blob/34f89df1d700be5143b9dbcc9886202fd2bfd3ca/opal/corelib/basic_object.rb
  # the point of this is to have #instance_eval with irb: true 
  def repl_eval( cmd, eval_in_self = true, keep_local_vars = true )
    repl_eval_options = { file: '(eval)', eval: eval_in_self, irb: keep_local_vars }
    compiling_options = __OPAL_COMPILER_CONFIG__.merge(repl_eval_options)
    compiled = ::Opal.compile cmd, compiling_options
    block = ::Kernel.proc do
      %x{
        return (function(self) {
          return eval(compiled);
        })(self)
      }
    end

    %x{
      var old = block.$$s,
          result;
      block.$$s = null;
      // Need to pass $$eval so that method definitions know if this is
      // being done on a class/module. Cannot be compiler driven since
      // send(:instance_eval) needs to work.
      if (self.$$is_a_module) {
        self.$$eval = true;
        try {
          result = block.call(self, self);
        }
        finally {
          self.$$eval = false;
        }
      }
      else {
        result = block.call(self, self);
      }
      block.$$s = old;
      return result;
    }
  end

end

