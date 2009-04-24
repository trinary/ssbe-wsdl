class Client < ActiveRest::Model
  collection_resource do
    SYSTEM_SHEPHERD.discover_uri('http://systemshepherd.com/services/kernel', 'AllClients')
  end

  properties :name,:id

  def to_s
    name
  end
end
