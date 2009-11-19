require 'pathname'

$LOAD_PATH << Pathname(__FILE__).dirname

require "resourceful"
require "active_rest/logging"
require "active_rest/model"
require "active_rest/has_one_associations"

require "active_rest/ssj_transmuter"
require "active_rest/trace_logging"

module ActiveRest

end


