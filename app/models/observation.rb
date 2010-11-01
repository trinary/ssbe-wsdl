class Observation < ActiveRest::Model
  properties :value,:recorded_at

  class WsType < ActionWebService::Struct
      member :value,:float
      member :recorded_at,:string
  end
  def to_s
    "#{value},#{timestamp}"
  end
  def to_ws
    r = Observation::WsType.new
    r.value = value
    r.recorded_at = recorded_at
    r
  end
end
