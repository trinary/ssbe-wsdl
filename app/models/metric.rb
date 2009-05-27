class Metric < ActiveRest::Model
  properties :metric_type,:observations,:historical_observations

  class WsType < ActionWebService::Struct
      member :id,:string
      member :metric_type,:string
      member :href,:string
      member :observations_href,:string
      member :historical_observations_href,:string
      member :status_href,:string
  end
  def to_s
    metric_type["path"]
  end
  def observations_href
    observations["href"]
  end
  def historical_observations_href
    historical_observations["href"]
  end
  def status_href
    status["href"]
  end
  def to_ws
    r = Metric::WsType.new
    r.id = id
    r.href = href
    r.metric_type = metric_type["path"]
    r.observations_href = observations_href
    r.historical_observations_href = historical_observations_href
    r.status_href = status_href
    r
  end
end
