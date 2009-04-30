class SsbeController < ApplicationController
  wsdl_service_name 'Ssbe'
  web_service_api SsbeApi
  web_service_scaffold :invocation if Rails.env == 'development'

  def get_clients
    Client.get(:all).map{|c| c.to_ws}
  end

  def get_client(name)
    Client.get(:all).find{|c| c.name == name}.to_ws
  end

  def get_hosts(hosts_href)
    Host.send("get_every",hosts_href)
  end

  def get_hosts_for_client(client_href)
    c=Client.get(client_href)
    Host.send("get_every",c.hosts_href).map{|h| h.to_ws}
  end

  def get_metrics_for_host(host_href)
    h = Host.get(host_href)
    Metric.send("get_every",h.metrics_href).map{|m| m.to_ws}
  end

  def get_observations_for_metric(metric_href,begin_time, end_time)
    if begin_time.empty? 
      begin_time = (Time.now - 1.week).gmtime.xmlschema
    end
    if end_time.empty? 
      end_time = (Time.now - 1.day).gmtime.xmlschema
    end

    m = Metric.get(metric_href)
    href=m.observations_href + "?start=#{begin_time}&end=#{end_time}"
    Observation.send("get_every",href).map{|o| o.to_ws}
  end

  def get_historical_observations_for_metric(metric_href,begin_time,end_time)
    if begin_time.empty? 
      begin_time = (Time.now - 1.week).gmtime.xmlschema
    end
    if end_time.empty? 
      end_time = (Time.now - 1.day).gmtime.xmlschema
    end

    m = Metric.get(metric_href)
    href=m.historical_observations_href + "?start=#{begin_time}&end=#{end_time}"
    HistoricalObservation.send("get_every",href).map{|o| o.to_ws}
  end
end
