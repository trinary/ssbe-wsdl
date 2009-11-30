#SYSSHEP_BACKEND_DOMAIN_NAME = '@@FQDN@@'.sub(/@@.*@@/, 'ssbe.localhost') # the fully qualified domain name of the SystemShepherdBackEnd, or localhost if haven't been given the domain name

CORE_FQDN=ENV['CORE_FQDN']
ALARM_FQDN=ENV['ALARM_FQDN']
SSBE_USER=ENV['SSBE_USER']
SSBE_PASS=ENV['SSBE_PASS']

DEFAULT_HTTP_ACCESSOR = CORE_HTTP_ACCESSOR = Resourceful::HttpAccessor.new(:logger => RAILS_DEFAULT_LOGGER,
                                                                           :cache_manager => Resourceful::InMemoryCacheManager.new)
require 'system_shepherd/ssbe_authenticator'
DEFAULT_HTTP_ACCESSOR.auth_manager.add_auth_handler(SSBEAuthenticator.new(SSBE_USER, SSBE_PASS))


