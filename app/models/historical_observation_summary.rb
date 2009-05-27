class HistoricalObservationSummary
  attr_accessor :begin_time
  attr_accessor :num_points
  attr_accessor :min
  attr_accessor :max
  attr_accessor :mean
  attr_accessor :mean_std_dev

  def initialize(args)
    @begin_time = args[:begin_time]
    @num_points = args[:num_points]
    @min = args[:min]
    @max = args[:max]
    @mean = args[:mean]
    @mean_std_dev = args[:mean_std_dev]
  end

  class WsType < ActionWebService::Struct
      member :begin_time, :string
      member :num_points, :int
      member :min, :float
      member :max, :float
      member :mean, :float
      member :mean_std_dev, :float
  end
  def to_s
    "#{begin_time},#{mean}"
  end
  def to_ws
    r = HistoricalObservationSummary::WsType.new
    r.begin_time = @begin_time
    r.num_points = @num_points
    r.min = @min
    r.max = @max
    r.mean = @mean
    r.mean_std_dev = @mean_std_dev
    r
  end
end
