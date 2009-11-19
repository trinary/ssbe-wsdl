module ActiveResource
  class Connection

    class << self
      def default_header
        class << self ; attr_reader :default_header end
        @default_header = { 'Content-Type' => 'application/xml', 'Accept' => 'application/xml' }
      end
    end

    def initialize(site, proxy_host = nil, proxy_port = nil)
      raise ArgumentError, 'Missing site URI' unless site
      self.site = site
      @proxy_host, @proxy_port = proxy_host, proxy_port
    end

    def get(path, headers = {})
      response = request(:get, path, build_request_headers(headers))

      if headers['Accept'] =~ /json/
        json_from_response response
      else
        xml_from_response response
      end
    end

    def xml_from_response(response)
      from_data(Hash.from_xml(response.body))
    end

    def json_from_response(response)
      from_data(ActiveSupport::JSON.decode(response.body))
    end

    protected

    def http
      unless @http
        if @proxy_host
          @http = Net::HTTP::Proxy(@proxy_host, @proxy_port).new(@site.host, @site.port)
        else
          @http = Net::HTTP.new(@site.host, @site.port)
        end
        @http.use_ssl     = @site.is_a?(URI::HTTPS)
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @http.use_ssl
      end

      @http
    end

    def from_data(data)
      if data.is_a?(Hash) && data.keys.size == 1
        data.values.first
      else
        data
      end
    end

  end
end
