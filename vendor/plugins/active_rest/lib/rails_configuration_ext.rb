require 'active_support'

module ActiveRest
  class RailsConfigurator
    def initialize
      @uris = {}
      @auth_credentials = []
    end
    
    # handles setting well known URIs
    def method_missing_with_named_uri_setting(method_name, *args, &block)
      if uri_name = method_name.to_s[/.*(?=_uri=$)/] and 1 == args.size
        @uris[uri_name.to_sym] = args.first
      else
        method_missing_without_named_uri_setting(method_name, *args, &block)
      end
    end
    alias_method_chain :method_missing, :named_uri_setting

    
    def auth_credentials
      @auth_credentials
    end 
    
    def logger=(a_logger)
      @logger = a_logger
    end
    
    def configure_active_rest
      require 'active_rest'
      
      ActiveRest.logger = if @logger
                            @logger
                          elsif defined?(RAILS_DEFAULT_LOGGER)
                            RAILS_DEFAULT_LOGGER
                          else
                            nil
                          end

      @uris.each do |name, uri|
        ActiveRest.named_uris[name] = uri
      end
      
      creds_sans_dups = {} 
      @auth_credentials.each do |creds|
        creds_sans_dups[creds[:realm]] = creds
      end
      # we have all the credentials but with any duplicates removed
      
      creds_sans_dups.values.each do |creds|
        ActiveRest.auth_credentials(creds)
      end
    end 
  end 
end 

Rails::Configuration.class_eval do
  def active_rest
    @active_rest ||= ActiveRest::RailsConfigurator.new
  end  
end

