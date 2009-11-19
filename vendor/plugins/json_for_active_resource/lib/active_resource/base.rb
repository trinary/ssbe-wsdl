module ActiveResource
  class Base

    class << self
      def connection(refresh = false)
        if defined?(@connection) or superclass == Object
          @connection = Connection.new(site, @proxy_host, @proxy_port) if refresh || @connection.nil?
          @connection
        else
          superclass.connection
        end
      end

      def default_http_proxy(host, port)
        @proxy_host, @proxy_port = host, port
      end

      def get(path)
        uri = URI.parse(path)
        raise ArgumentError, "host and port do not match" unless uri.host == connection.site.host and uri.port == connection.site.port
        puts uri.path
        instantiate_single_or_collection(connection.get(uri.path, headers))
      end

      def instantiate_single_or_collection(document)
        if document.is_a?(Hash)
          instantiate_record(document)
        else
          instantiate_collection(document)
        end
      end

      def element_path(id, prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}#{collection_name}/#{id}#{query_string(query_options)}"
      end

      def collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
      end

    end

      protected

      # Update the resource on the remote service.
      def update
        # returning connection.put(element_path(prefix_options), to_xml, self.class.headers) do |response|
        returning connection.put(element_path(prefix_options), to_ssj, self.class.headers) do |response|
          load_attributes_from_response(response)
        end
      end

      # Create (i.e., save to the remote service) the new resource.
      def create
        #returning connection.post(collection_path, to_xml, self.class.headers) do |response|
        returning connection.post(collection_path, to_ssj, self.class.headers) do |response|
          self.id = id_from_response(response)
          load_attributes_from_response(response)
        end
      end

  end

end
