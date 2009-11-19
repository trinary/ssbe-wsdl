require 'json'
require 'active_rest/abstract_transmuter'
require 'active_rest/model'

module ActiveRest
  # Provides the ability to convert a properties hash into a
  # SystemShepherd JSON documents, and vise verse.
  class SsjTransmuter < AbstractTransmuter
    mime_type 'application/vnd.absolute-performance.sysshep+json'
    compatible_content_types 'application/x-sysshep+json'
    
    # Convert a properties hash representation of the resources into a
    # string representation for the format this transmuter handles.
    def marshal(properties)
      JSON(properties)
    end
    
    # Convert a string representation of a resource and convert it
    # into a properties hash, or array of properties hashes,
    # representation.
    def unmarshal(a_str)
      parsed = JSON.parse(a_str)
      
      parsed['items'] || parsed
    end
  end

  Model.transmuters << SsjTransmuter 
end


