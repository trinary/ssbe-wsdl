class HistoricalMetricSummary < ActiveRest::Model
  properties :href, :last_change, :value, :status, :metric, :last_updated, :begin_time, :end_time

  class WsType < ActionWebService::Struct
      member :href,:string
      member :hostname, :string
      member :client, :string
      member :metric_type, :string
      member :mean, :float
      member :min, :float
      member :max, :float
  end

  def to_s
    metric_status_href
  end

  def get_obs
    obs_href = Metric.get(metric["href"]).historical_observations["href"] + "?start=#{begin_time}&end=#{end_time}"
    HistoricalObservation.send("get_every",obs_href)
  end

  def calc_mean(obs)
    sum = 0
    return 0 if obs.empty?
    obs.map(&:mean).map {|i| sum += i}
    sum / obs.size
  end

  def calc_min(obs)
    min = Float::MAX
    obs.each do |o|
      min = o.min if o.min < min
    end
    min
  end

  def calc_max(obs)
    max = Float::MIN
    obs.each do |o|
      max = o.max if o.max > max
    end
    max
  end

  def to_ws
    r = HistoricalMetricSummary::WsType.new
    met = Metric.get(metric["href"])
    host = Host.get(met.host["href"])
    client = Client.get(host.client["href"])
    r.client = client.name
    r.hostname = host.hostname
    r.metric_type = met.metric_type["path"]
    obs = get_obs

    r.href = href
    r.mean = calc_mean(obs)
    r.max = calc_max(obs)
    r.min = calc_min(obs)
    r
  end
end
