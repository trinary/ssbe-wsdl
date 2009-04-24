class SsbeController < ApplicationController
  wsdl_service_name 'Ssbe'
  web_service_api SsbeApi
  web_service_scaffold :invocation if Rails.env == 'development'

  def get_clients
    Client.get(:all)
  end
  def get_hosts
    ["host 1","host 2"]
  end
  def get_metrics
    ["metric 1","metric 2"]
  end
  def get_observations
    ["obs 1","obs 2"]
  end
  def get_hosts_for_client(client)
    ["host that belongss to #{client}"]
  end
end
