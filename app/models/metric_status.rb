class MetricStatus < ActiveRest::Model
  properties :href, :last_change, :value, :status, :last_updated, :metric

  class WsType < ActionWebService::Struct
      member :href,:string
      member :status,:string
      member :value, :float
      member :last_updated, :string
      member :last_change, :string
      member :hostname, :string
      member :client, :string
      member :metric_type, :string
  end

  def to_s
    metric_status_href
  end

  def to_ws
    r = MetricStatus::WsType.new
    met = Metric.get(metric["href"])
    host = Host.get(met.host["href"])
    client = Client.get(host.client["href"])
    r.client = client.name
    r.hostname = host.hostname
    r.metric_type = met.metric_type["path"]

    r.href = href
    r.status = status
    r.value = value
    r.last_updated = last_updated
    r.last_change = last_change
    r
  end
end
