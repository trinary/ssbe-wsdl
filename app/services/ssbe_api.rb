class SsbeApi < ActionWebService::API::Base
  api_method :get_clients, :returns => [[Client::WsType]]
  api_method :get_client, :returns => [Client::WsType], :expects => [:name => :string]
  api_method :get_metrics_for_host, :returns => [[Metric::WsType]], :expects => [:host_href => :string]
  api_method :get_observations_for_metric, :returns => [[Observation::WsType]], :expects => [{:metric_href => :string},{:begin_time => :string}, {:end_time => :string}]
  api_method :get_historical_observations_for_metric, :returns => [[HistoricalObservation::WsType]], :expects => [{:metric_href => :string},{:begin_time => :string}, {:end_time => :string}]
  api_method :get_hosts_for_client, :returns => [[Host::WsType]], :expects => [:client_href => :string]
  api_method :get_metric_status, :returns => [MetricStatus::WsType], :expects => [{:metric_status_href => :string}]
  api_method :get_observation_summary, :returns => [[ObservationSummary::WsType]], :expects => [{:metric_href => :string}, {:frequency_minutes => :int}, {:duration_hours => :int}]
  api_method :get_historical_observations_summary, :returns => [[HistoricalObservationSummary::WsType]], :expects => [{:metric_href => :string},{:frequency_hours => :int},{:begin_date => :string},{:end_date => :string}]
end
