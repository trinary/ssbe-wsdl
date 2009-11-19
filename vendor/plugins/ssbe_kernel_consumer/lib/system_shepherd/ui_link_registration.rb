require 'json'
require 'system_shepherd'
require 'thread'
require 'addressable/uri'

class SystemShepherd

  def register_ui_link(id, title, target, category)
    json_doc = JSON.generate(:id        => id,
                             :target    => target,
                             :title     => title,
                             :category  => category)
    
    begin                                      
      logger.debug "Registering #{id} as #{target}"
      http_accessor.resource(specific_ui_link_uri(id)).put(json_doc,
                                                           :content_type => 'application/vnd.absolute-performance.sysshep+json', 
                                                           :accept => 'application/vnd.absolute-performance.sysshep+json')
      logger.info "#{id} link successfully registered with System Shepherd."

    rescue Exception => e
      logger.error "Unable to register #{id} link (cause: #{e.message})."
      
      if defined?(RAILS_ENV) and RAILS_ENV == 'production'
        # We are in production.  Retry until it succeeds.
        logger.info "Will retry UI Link registration in 10 seconds."
        logger.flush if logger.respond_to?(:flush)
        sleep 10
        retry
        
      else
        # We are not in production so just log the failure and keep going.
        logger.debug "Skipping UI link registration because environment is #{RAILS_ENV}."
        logger.flush if logger.respond_to?(:flush)
      end
    end
  end
  
  private 
  def specific_ui_link_uri(id)
      Addressable::URI.expand_template(SYSTEM_SHEPHERD.discover_uri("http://systemshepherd.com/services/kernel", "UiLink"),
                                       "id" => id.to_s).to_s
  end
end
