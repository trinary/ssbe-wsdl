class SsbeApi < ActionWebService::API::Base
  api_method :get_clients, :returns => [[Client]]
  api_method :get_metrics, :returns => [[:string]]
  api_method :get_observations, :returns => [[:string]]
  api_method :get_client, :returns => [Client], :expects => [:name => :string]
end
