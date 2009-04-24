class SsbeApi < ActionWebService::API::Base
  api_method :get_clients, :returns => [[:string]]
  api_method :get_hosts, :returns => [[:string]]
  api_method :get_hosts_for_client, :returns => [[:string]], :expects => [:string]
  api_method :get_metrics, :returns => [[:string]]
  api_method :get_observations, :returns => [[:string]]
end
