require 'advanced_http'
require 'openid'
require 'active_rest'

class AuthenticatingOpenIdFetcher < OpenID::Fetcher
  
  def http
    @http ||= AdvancedHttp::HttpAccessor.new(ActiveRest)
  end 
  
  def get(url)
    resource = http.resource(url)
    response = resource.get
    
    [resource.effective_uri.to_s, response.body]
  rescue AdvancedHttp::HttpRequestError => e
    nil
  end

  def post(url, body)
    resource = http.resource(url)
    response = resource.post(body, "application/x-www-form-urlencoded") 
    
    [resource.effective_uri.to_s, response.body]
  rescue AdvancedHttp::HttpRequestError => e
    nil
  end

  protected
  def http
    @http_accessor ||= AdvancedHttp::HttpAccessor.new(:logger => ActiveRest.logger, :authentication_info_provider => ActiveRest)
  end
end 

