class HistoricalObservation < ActiveRest::Model
  properties :median, :max, :begin_time, :num_points, :mean, :stdev, :min

  class WsType < ActionWebService::Struct
    member :max,:float
    member :begin_time, :datetime
    member :num_points, :int
    member :mean,:float
    member :stdev,:float
    member :min,:float
  end
  def to_s
    "#{mean},#{begin_time}"
  end
  def to_ws
    r = HistoricalObservation::WsType.new
    r.max = max
    r.begin_time = begin_time
    r.num_points = num_points
    r.mean = mean
    r.stdev = stdev
    r.min= min
    r
  end
end
