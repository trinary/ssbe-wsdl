module ActiveRest
  class << self
    @@logger = nil
    def logger=(a_logger)
      @@logger = a_logger
      Model.http.logger = a_logger
    end
    def logger
      @@logger ||= returning Logger.new(STDERR) do |l|
        l.level = Logger::WARN
        l.warn("ActiveRest: logger not configured.  Logging level raised to WARN and directed to STDERR." )
      end
    end
    
    # Logs +message+ to logger at the info level
    def info(message)
      logger.info(message) if logger
    end
    
    # Logs +message+ to logger at the debug level
    def debug(message)
      logger.debug(message) if logger
    end

    # Logs +message+ to logger at the warning level
    def warn(message)
      logger.warn(message) if logger
    end
  end
end
