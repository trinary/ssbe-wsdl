require 'system_shepherd/resource_discovery'

SYSTEM_SHEPHERD = SystemShepherd.new("http://#{CORE_FQDN}/service_descriptors", :http_accessor => DEFAULT_HTTP_ACCESSOR)

