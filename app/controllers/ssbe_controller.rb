class SsbeController < ApplicationController
  wsdl_service_name 'Ssbe'
  web_service_api SsbeApi
  web_service_scaffold :invocation #if Rails.env == 'development'

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

  def get_metric_status(metric_status_href)
    MetricStatus.get(metric_status_href).to_ws
  end

  def get_observation_summary(metric_href,frequency_minutes, duration_hours)
    if frequency_minutes.nil?
      frequency_minutes = 60
    end
    if duration_hours.nil?
      duration_hours = 24
    end

    m = Metric.get(metric_href)
    end_time = Time.now.gmtime.xmlschema
    begin_time = (Time.now.gmtime - duration_hours.hours).xmlschema
    href = m.observations_href + "?start=#{begin_time}&end=#{end_time}"

    counter = Time.parse(begin_time)
    to_roll = []
    summ = []

    obs = Observation.send("get_every",href)
    obs.sort! {|a,b| Time.parse(a.recorded_at) <=> Time.parse(b.recorded_at)}
    obs.each do |o|
      if Time.parse(o.recorded_at) < counter + frequency_minutes.minutes
        to_roll  << o
      else
        counter += frequency_minutes.minutes
        summ <<  summarize(to_roll)
        to_roll = []
        to_roll << o
      end
    end

    summ
  end

  private

  def summarize(obs_list)
    s = 0.0
    max = 0.0
    min = 0.0
    obs_list.each do |o|
      s += o.value
      max = o.value if o.value > max
      max = o.value if o.value < min
    end
    mean = s/obs_list.size
    ObservationSummary.new({:num_points => obs_list.size, :max => max, :min => min, :mean => mean, :begin_time => obs_list.first.recorded_at }).to_ws
  end

end
