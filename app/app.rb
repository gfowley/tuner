require 'opal' 
require 'browser'
require 'repl'

puts "Opal #{RUBY_ENGINE_VERSION}"

$document.ready do
  puts "Ready"
  REPL.run
  # REPL.rescue { raise "oops!" }
end

