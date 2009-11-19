module ActiveRest
  # Provides the ability to convert a properties hash into a string
  # representation, and vise verse.  The string representations are
  # sent to and from a remote resource via HTTP.
  class AbstractTransmuter
    # Indicates the sort of representations this transmuter can
    # marshal to and from.
    def mime_type
      raise NotImplementedError
    end
    
    # Convert a properties hash representation of the resources into a
    # string representation for the format this transmuter handles.
    def marshal(properties)
      raise NotImplementedError
    end
    
    # Convert a string representation of a resource into a properties
    # hash, or array of properties hashes, representation.
    def unmarshal(a_str)
      raise NotImplementedError
    end

    def content_type_pattern
      raise NotImplementedError
    end
    
    # Class methods
    class << self
      protected      
     
      # Defines the mime_type of the transmuter class on which this is
      # called to be +a_mime_type+.  After this method is call it will
      # be replaced with a method that returns the mime type handled
      # by the class.
      def mime_type(a_mime_type)
        a_mime_type = a_mime_type.to_str
        mt_body = lambda{a_mime_type}
        
        ctp = Regexp.compile('(?:^|\s)' + Regexp.escape(a_mime_type)  + '(?:[;\s]|$)', Regexp::IGNORECASE)
        ctp_body = lambda{ctp}
        
        define_method(:mime_type, &mt_body)
        (class << self; self; end).send(:define_method, :mime_type, &mt_body)
        compatible_content_types()
      end
      
      def compatible_content_types(*mime_media_types)
        mime_media_types = (mime_media_types.clone << mime_type).uniq
        
        ctp = Regexp.compile('(?:^|\s)' + mime_media_types.map{|an_mt| Regexp.escape(an_mt)}.join('|')  + 
                             '(?:[;\s]|$)', Regexp::IGNORECASE)
        ctp_body = lambda{ctp}
        (class << self; self; end).send(:define_method, :content_type_pattern, &ctp_body)
      end
    end
  end
end
