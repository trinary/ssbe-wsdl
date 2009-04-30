class Host < ActiveRest::Model

  properties :hostname,:client,:metrics

  class WsType < ActionWebService::Struct
    member :id,:string
    member :hostname,:string
    member :href,:string
    member :metrics_href,:string
  end
  def to_s
    hostname
  end
  def metrics_href
    metrics["href"]
  end
  def to_ws
    r = Host::WsType.new
    r.id = id
    r.href = href
    r.hostname = hostname
    r.metrics_href = metrics_href
    r
  end
end
