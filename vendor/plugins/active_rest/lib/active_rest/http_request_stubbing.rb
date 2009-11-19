require 'resourceful'

module ActiveRest
  module HttpRequestStubbing
    @@stubbing_allowed = true
    def self.silently_disable_all_stubs
      @@stubbing_allowed = false
    end

    def stub_http_request(uri, response_body)
      return unless @@stubbing_allowed

      ActiveRest::Model.http.stub_request(:get, uri, "application/vnd.absolute-performance.sysshep+json", response_body)
    end
  end
end
