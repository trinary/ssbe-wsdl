require 'json'
require 'system_shepherd'

class SystemShepherd
  
  # Indicates that the desired resource was not found in the service
  # descriptor specified.
  class NoSuchResource < Exception; end
  
  # Indicates that the desired service is not available in the System
  # Shepherd constellation.
  class NoSuchService < Exception; end
    
  # Creates, and returns, a Proc that will discover and return the
  # URI of a SystemShepherd resource on the demand.
  def uri_discoverer(service_type, resource_name)
    rd = ResourceDescriptor.new(self, service_type, resource_name)
    lambda { rd.href }    
  end
  alias resource_discoverer uri_discoverer
  
  def discover_uri(service_type, resource_name)
    ResourceDescriptor.new(self, service_type, resource_name).href
  end

  def discover_kernel_uri(resource_name)
    discover_uri("http://systemshepherd.com/services/kernel", resource_name)
  end

  # This class is used to discover, at runtime, dereferencable URIs
  # for resources that are part of SystemShepherd.  
  # 
  # This class is not normally used directly. You probably want to look at
  # +SystemShepherd#resource_discoverer()+ instead.
  class ResourceDescriptor
    attr_reader :service_type, :resource_name
    
    def initialize(sys_shep, service_type, resource_name)
      @sys_shep = sys_shep
      @service_type = service_type
      @resource_name = resource_name
    end
    
    # A dereferencable URI for the resource described by this object.
    def href
      resource_desc = service_description['resources'].find{|r| r['name'] == resource_name} || 
        raise(NoSuchResource, "#{resource_name} resource is not exposed by the <#{service_type}> service")
      
      resource_desc['href']
    end
    
    private 
    attr_reader :sys_shep

    def http
      @sys_shep.http_accessor
    end
    
    
    # A dereferencable URI for the descriptor of the service of which
    # resource is a part.
    def service_descriptor_href
      resp = http.resource(sys_shep.capabilities_uri).get(:accept => 'application/vnd.absolute-performance.sysshep+json')
 
      service_descriptors = JSON.parse(resp.body)['items']
      sd_ref = service_descriptors.find{|sd| sd['service_type'] == service_type} || 
        raise(NoSuchService, "<#{service_type}> service is not available in this SystemShepherd")
      
      sd_ref['href']
    end
    
    # The full description of the service to which this resource belongs
    # as a Hash.
    def service_description
      resp = http.resource(service_descriptor_href).get(:accept => 'application/vnd.absolute-performance.sysshep+json')
      JSON.parse(resp.body)
    end
  end
end
