class SsbeController < ApplicationController
  wsdl_service_name 'Ssbe'
  web_service_api SsbeApi
  wsdl_namespace 'http://absolute-performance.com/wsdl'
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

  def get_metric_status(metric_href)
    href=Metric.get(metric_href).status_href
    MetricStatus.get(href).to_ws
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
    summary = []

    obs = Observation.send("get_every",href)
    obs.sort! {|a,b| Time.parse(a.recorded_at) <=> Time.parse(b.recorded_at)}
    obs.each do |o|
      if Time.parse(o.recorded_at) < counter + frequency_minutes.minutes
        to_roll  << o
      else
        counter += frequency_minutes.minutes
        summary <<  summarize(to_roll, counter.xmlschema) unless to_roll.size == 0
        to_roll = []
        to_roll << o
      end
    end

    summary
  end

  def get_historical_observations_summary (metric_href,frequency_hours, begin_time, end_time)
    if begin_time.empty?
      begin_time = Time.now.gmtime - 30.days
    end
    if end_time.empty?
      end_time = Time.now.gmtime - 1.day
    end
    
    counter = Time.parse(begin_time)
    to_roll = []
    summary = []

    href = Metric.get(metric_href).historical_observations_href + "?start=#{begin_time}&end=#{end_time}"
    hobs = HistoricalObservation.send("get_every",href)

    while counter < Time.parse(end_time) do
      puts "#{counter}\t#{counter + frequency_hours.hours}"
      summary << hist_summarize(hobs.find_all{|o| Time.parse(o.begin_time) >= counter && Time.parse(o.begin_time) < counter + frequency_hours.hours}, counter.xmlschema)
      counter += frequency_hours.hours
    end

    summary
  end

  def find_metrics_status(client_regex,host_regex,metric_regex)
    statuses = []
    metrics = find_metrics(client_regex,host_regex,metric_regex)
    metrics.each do |m|
      statuses << get_metric_status(m.href)
    end
    statuses
  end

  def find_metrics_summary(client_regex,host_regex,metric_regex,duration,percentile)
    metrics = find_metrics(client_regex,host_regex,metric_regex)
    summaries = []
    metrics.each do |m|
      ms=MetricSummary.get(m.status["href"])
      ms.begin_time = (Time.now.gmtime - duration.minutes).xmlschema
      ms.end_time   = Time.now.gmtime.xmlschema
      ms.percentile = percentile
      summaries << ms.to_ws
    end
    summaries
  end

  def find_historical_metrics_summary(client_regex,host_regex,metric_regex,start_time,end_time,percentile)
    metrics = find_metrics(client_regex,host_regex,metric_regex)
    summaries = []
    metrics.each do |m|
      ms=HistoricalMetricSummary.get(m.status["href"])
      ms.begin_time = start_time
      ms.end_time   = end_time
      summaries << ms.to_ws
    end
    summaries
  end

  private

  def find_metrics(client_regex=".*", host_regex=".*", metric_regex=".*")
    clients = hosts = metrics = []
    clients += Client.get(:all).select {|c| c.name =~ /#{client_regex}/ }
    clients.each do |c|
      hosts += Host.send("get_every",c.hosts_href).select { |h| h.hostname =~ /#{host_regex}/}
    end
    hosts.each do |h|
      metrics += Metric.send("get_every",h.metrics_href).select { |m| m.metric_type["path"] =~ /#{metric_regex}/}
    end
    metrics
  end

  def summarize(obs_list, begin_time)
    s = 0.0
    mean = 0.0
    max= obs_list.empty? ? 0.0 : Float::MIN
    min= obs_list.empty? ? 0.0 : Float::MAX
    obs_list.each do |o|
      s += o.value
      max = o.value if o.value > max
      min = o.value if o.value < min
    end
    mean = s/obs_list.size unless obs_list.empty?
    ObservationSummary.new({:num_points => obs_list.size, :max => max, :min => min, :mean => mean, :begin_time => begin_time }).to_ws
  end

  def hist_summarize(obs_list, begin_time)
    s=0.0
    stdev_s=0.0
    max= obs_list.empty? ? 0.0 : Float::MIN
    min= obs_list.empty? ? 0.0 : Float::MAX
    mean=0.0
    num=0
    stdev_mean = 0.0

    obs_list.each do |o|
      num += o.num_points
      s += o.mean
      stdev_s += o.stdev
      max = o.max if o.max > max
      min = o.min if o.min < min
    end
    mean = s/obs_list.size unless obs_list.empty?
    stdev_mean = stdev_s/obs_list.size unless obs_list.empty?

    HistoricalObservationSummary.new({:begin_time => begin_time, :num_points => num, :min => min, :max => max, :mean => mean, :mean_std_dev => stdev_mean}).to_ws
  end
end
