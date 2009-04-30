class Client < ActiveRest::Model
  collection_resource do
    SYSTEM_SHEPHERD.discover_uri('http://systemshepherd.com/services/kernel', 'AllClients')
  end

  properties :name,:id,:hosts,:longname

  class WsType < ActionWebService::Struct
      member :id,         :string
      member :name,       :string
      member :href,       :string
      member :hosts_href, :string
  end
  def to_s
    name
  end
  def to_ws
    r = Client::WsType.new
    r.name = name
    r.id = id
    r.href = href
    r.hosts_href = hosts_href
    r
  end
  def hosts_href
    hosts["href"]
  end
end
