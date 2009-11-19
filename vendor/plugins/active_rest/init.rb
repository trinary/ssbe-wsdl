require 'pathname'

require "active_rest"
require "rails_configuration_ext"

initializer.configuration.active_rest.configure_active_rest
# we have pulled the configuration information from the Rails configuration

