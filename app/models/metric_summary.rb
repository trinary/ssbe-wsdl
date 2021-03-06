class MetricSummary < ActiveRest::Model
  properties :href, :last_change, :value, :status, :metric, :last_updated, :begin_time, :end_time, :percentile

  class WsType < ActionWebService::Struct
      member :href,:string
      member :status,:string
      member :value, :float
      member :last_updated, :string
      member :last_change, :string
      member :hostname, :string
      member :client, :string
      member :metric_type, :string
      member :percentile_value, :float
      member :mean, :float
  end

  def to_s
    metric_status_href
  end

  def get_obs
    obs_href = Metric.get(metric["href"]).observations["href"] + "?start=#{begin_time}&end=#{end_time}"
    Observation.send("get_every",obs_href)
  end

  def calc_percentile(pct,obs)
    return 0 if obs.empty?
    obs.map(&:value).sort[(pct*obs.length).ceil-1]
  end
  def calc_mean(obs)
    return 0 if obs.empty?
    obs.map(&:value).sum / obs.size
  end

  def to_ws
    r = MetricSummary::WsType.new
    met = Metric.get(metric["href"])
    host = Host.get(met.host["href"])
    client = Client.get(host.client["href"])
    obs=get_obs
    r.client = client.name
    r.hostname = host.hostname
    r.metric_type = met.metric_type["path"]

    r.href = href
    r.status = status
    r.value = value
    r.last_updated = last_updated
    r.last_change = last_change
    r.percentile_value = calc_percentile(percentile,obs)
    r.mean = calc_mean(obs)
    r
  end
end
