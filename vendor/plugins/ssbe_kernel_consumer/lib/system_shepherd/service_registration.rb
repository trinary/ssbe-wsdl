require 'json'
require 'system_shepherd'
require 'thread'

class SystemShepherd
  
  def register_service(service_type, service_uri)
    json_doc = JSON.generate(:service_type => service_type, 
                             :href => service_uri)
    begin
      http_accessor.resource(capabilities_uri).post(json_doc,
                                                    :content_type => 'application/vnd.absolute-performance.sysshep+json', 
                                                    :accept => 'application/vnd.absolute-performance.sysshep+json')
      logger.info "<#{service_type}> successfully registered with System Shepherd."
      
    rescue Exception => e
      logger.error "Unable to register <#{service_type}> (cause: #{e.message})."
      
      if defined?(RAILS_ENV) and RAILS_ENV == 'production'
        # We are in production.  Retry until it succeeds.
        logger.info "Will retry service registration in 10 seconds."
        logger.flush if logger.respond_to?(:flush)
        sleep 10
        retry
        
      else
        # We are not in production so just log the failure and keep going.
        logger.debug "Skipping service registration because environment is #{RAILS_ENV}."
        logger.flush if logger.respond_to?(:flush)
      end
    end
  end
  
end

