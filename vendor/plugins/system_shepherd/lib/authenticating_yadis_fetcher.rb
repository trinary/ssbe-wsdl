require 'advanced_http'
require 'openid'
require 'active_rest'
require 'yadis'

class AuthenticatingYadisFetcher
  
  def http
    @http ||= AdvancedHttp::HttpAccessor.new(ActiveRest)
  end 
  
  def get(url, headers)
    opts = {}
    opts[:accept] = headers['Accept'] if headers['Accept']
    
    resource = http.resource(url)
    response = resource.get(opts)
    
    [resource.effective_uri.to_s, response]
  rescue AdvancedHttp::HttpRequestError => e
    nil
  end

  protected
  def http
    @http_accessor ||= AdvancedHttp::HttpAccessor.new(:logger => ActiveRest.logger, :authentication_info_provider => ActiveRest)
  end
end 

NetHTTPFetcher = AuthenticatingYadisFetcher
