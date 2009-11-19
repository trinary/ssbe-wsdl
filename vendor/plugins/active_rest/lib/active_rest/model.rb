require 'net/http'
require 'resourceful'
require 'active_support'
require 'active_rest/logging'
require 'active_rest/abstract_transmuter'
require 'active_rest/trace_logging'
require 'validatable'
require 'system_shepherd/ssbe_authenticator'

module ActiveRest  

  class ModelInvalid < Exception
    attr_reader :model
    
    def initialize(a_model)
      super("Model #{a_model} is not valid")
    end
  end
  
  # An object representation of a resource available via HTTP.
  #
  # The logical attributes of resource that is represented as an
  # +ActiveRest::Model+ are called properties.
  #
  # ActiveRest models must have followable URI.  This URI is the
  # +href+ property.  A models +href+ may be nil iff the resource
  # represented by the model does not yet exist on the web.
  class Model
    include TraceLogging
    include Validatable
    
    attr_reader :properties

    # :call-seq:
    #  initialize()
    #  initialize(properties)
    #
    # Initializes a newly created ActiveRest::Model.
    def initialize(properties = {})
      @properties = {}
      properties.each do |key, val|
        send(:"#{key}=", val) if respond_to?(:"#{key}=", true)
      end      
    end

    # The URI of a collection of which this model is (or will
    # be upon save) a part.
    def collection_uri
      self.class.collection_uri
    end

    # A number which may be used to identify this object for storage
    # in Hash objects.
    def hash
      href.hash
    end

    # Indicates if +self+ is equal to +another+
    def eql?(another)
      another.kind_of?(self.class) and self.href == another.href
    end
    alias == eql?

    # Posts/puts local changes to this model to the remote resource.
    def save
      raise ModelInvalid.new(self) unless valid?
      # This model is valid so save it.
      
      if new?
        create_resource
      else
        update_resource
      end
    end

    # Indicates if this Model is backed by an existing resource or
    # not.  If it is new it has never been saved to the server.
    def new?
      href.nil?
    end
    
    # A followable URI for the resource which this model represents,
    # if there is one.  This is +nil+ for new models.
    def href
      properties[:href]
    end

    # A followable URI for the resource which this model represents,
    # if there is one.  This is +nil+ for new models.
    def href=(an_href)
      properties[:href] = an_href
    end

    def reload
      properties.update(self.class.get(properties[:href]).properties)
    end

    def update_properties(properties = {})
      properties.each do |key, val|
        send(:"#{key}=", val)
      end
    end
    
    protected
    def update_resource
      trace_log "Updating resource '#{href}'"
      t = transmuters.first.new
      resp = http[href].put(t.marshal(self.properties), :content_type => t.mime_type, :accept => t.mime_type)
      return false unless resp.is_a?(Net::HTTPOK) or resp.is_a?(Net::HTTPNoContent)
      # we got the correct response
      self.reload

    rescue Resourceful::UnsuccessfulHttpRequestError => e
      logger.error e.message
      trace_log e.response.body
      trace_log e.request.body

      raise e    
    end

    def create_resource
      trace_log("Creating #{self.class.name} resource in '#{collection_uri}'")
      t = transmuters.first.new
      resp = http.resource(collection_uri).post(t.marshal(self.properties), :content_type => t.mime_type, :accept => t.mime_type)
      # we got the correct response
      self.href = resp.header['location'].first
      self.reload

    rescue Resourceful::UnsuccessfulHttpRequestError => e
      logger.error e.message
      trace_log e.response.body
      trace_log e.request.body
      
      raise e      
    end
    
    # An HttpAccessor that can be used to make HTTP requests
    def http
      self.class.http
    end
    
    def logger
      ActiveRest.logger
    end
    
    class_inheritable_array :transmuters
    self.transmuters = []

    protected
    
    # Class methods
    class << self
      include TraceLogging
      
      # :call-seq:
      #  get(a_uri)
      #  get(:all, :from => a_uri)
      #
      # Instantiates one or more model objects based on the
      # representations returned by getting +a_uri+.
      def get(*args)
        options = args.last.is_a?(Hash) ? args.last.clone : {}

        if :all == args.first
          uri = options.delete(:from) || collection_uri
          get_every(uri, options)
       elsif uri = args.first
          get_one(uri, options)
        else
          raise(ArgumentError,
                "Don't know what to do based on the arguments passed (#{args.inspect})")
        end
      end

      # An Resourceful::Accessor object that may be used to make HTTP
      # requests
      def http
        @@http_accessor ||= 
          returning Resourceful::HttpAccessor.new(:logger => ActiveRest,
                                                  :cache_manager => Resourceful::InMemoryCacheManager.new) do |http|
            http.auth_manager.add_auth_handler(SSBEAuthenticator.new('dev', 'dev'))
          end
      end

      # A URI indicating the default collection resource for models of this class.
      def collection_uri(a_uri = nil)
        raise NotImplementedError
      end

      
      protected

      def get_one(a_uri, options={})
        trace_log "Getting resource #{a_uri}"
        new(unmarshall(http[a_uri].get(:accept => acceptable_formats)))
      end

      def get_every(a_uri, options={})
        trace_log "Getting all resources in collection #{a_uri}"
        unmarshall(http[a_uri].get(:accept => acceptable_formats)).map do |an_item|
          self.new(an_item)
        end
      end

      # Defines one property of this object.  A property is an
      # property of the resource that will be provided by the
      # representations retrieved from the server.
      def property(prop_name, options = {})
        prop_name = prop_name.to_sym
        
        define_method(prop_name) do 
          @properties[prop_name]
        end
        
        define_method(:"#{prop_name}=") do |new_value|
          @properties[prop_name] = new_value            
        end 
        private :"#{prop_name}=" if options[:readonly]
      end

      # :call-seq:
      #   properties(*property_names)
      #   properties(*property_names, options = {})
      # 
      # Defines one or more properties of this object.  A property is
      # an property of the resource that will be provided by the
      # representations retrieved from the server.
      def properties(*prop_names_and_options)
        options = if prop_names_and_options.last.is_a?(Hash)
                    prop_names_and_options.pop
                  else
                    {}
                  end
        
        prop_names_and_options.each do |a_prop|
          property(a_prop, options.clone)
        end      
      end
      
      def acceptable_formats
        transmuters.map{|t| t.mime_type}
      end

      def unmarshall(an_http_resp)
        content_type = an_http_resp.header['content-type'].first
        t = transmuters.find{|t| t.content_type_pattern === content_type}

        t.new.unmarshal(an_http_resp.body)
      end
      
      # Sets the collection resource of this model to the specified
      # URI.  If +a_uri+ is a Proc it is expected to return the URI
      # (it will evaluated each time the URI is needed).  If a block
      # is provided it is treated the same as if +a_uri+ was a
      # the block
      def collection_resource(a_uri = nil, &block)
        a_uri = block if block_given?
        
        m_body = case a_uri
                 when Proc
                   a_uri
                 else
                   lambda{a_uri}
                 end
          
        (class << self; self; end).class_eval do 
          define_method(:collection_uri, &m_body) 
        end
      end
      
      
    end
  end

  class UnsupportedFormatError < Exception
    def initialize(mime_type)
      super("There is no transmuter for documents of type #{mime_type}")
    end
  end
end
