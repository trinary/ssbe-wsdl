require 'resourceful'

# SystemShepherd objects access to a particular System Shepherd Back
# End. 
class SystemShepherd
  attr_reader :capabilities_uri, :http_accessor, :logger
  
  # Initialize the SystemShepherd proxy thing
  #
  # Valid options are:
  #   +auth_info_provider+:: An authentication information provider to
  #     use when making http requests against SystemShepherd.
  #
  #   +http_accessor+:: An AdvancedHttp::HttpAccessor object to use when making http
  #     requests.  Default: +AdvancedHttp::HttpAccessor.new()+
  #
  #   +logger+:: The Logger object to which messages related to
  #     SystemShepherd interaction should be sent.
  def initialize(ssbe_capabilities_uri, options)
    @capabilities_uri = ssbe_capabilities_uri
    @logger = options[:logger]
    @http_accessor = options[:http_accessor] || 
      Resourceful::HttpAccessor.new(:logger => logger)
  end
  
end
