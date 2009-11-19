require 'rubygems'
require 'pathname'
require 'spec'

$LOAD_PATH << Pathname(__FILE__).dirname + "../lib"

require "active_support"
require "active_record"
require 'pp'

Spec::Runner.configure do |config|
  config.mock_with :mocha
end
