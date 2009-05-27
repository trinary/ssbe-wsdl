class MetricStatus < ActiveRest::Model
  properties :href, :last_change, :value, :status, :last_updated, :metric_href

  class WsType < ActionWebService::Struct
      member :href,:string
      member :status,:string
      member :value, :float
      member :last_updated, :string
      member :last_change, :string
  end
  def to_s
    metric_status_href
  end

  def to_ws
    r = MetricStatus::WsType.new
    r.href = href
    r.status = status
    r.value = value
    r.last_updated = last_updated
    r.last_change = last_change
    r
  end
end
