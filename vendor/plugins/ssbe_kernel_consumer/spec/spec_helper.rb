# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.

require 'rubygems'
require 'pathname'
require 'spec'
require 'pp'

def add_load_path(path)
  $LOAD_PATH << Pathname(__FILE__).dirname + path
end

add_load_path '../../active_rest/lib'
add_load_path '../lib'

require 'active_rest'
require 'active_rest/http_request_stubbing'
require 'resourceful'

Spec::Runner.configure do |config|
  config.include(ActiveRest::HttpRequestStubbing)
end
