module ActiveRest
  class << self
    def enable_trace_logging
      @trace_logging = true
    end
    
    def trace_logging?
      @trace_logging = false if @trace_logging.nil? 
      
      @trace_logging
    end
  end
  
  # This module provides behavior related to trace logging.
  module TraceLogging   
    def trace_log(message)
      ActiveRest.logger.debug(message) if ActiveRest.trace_logging?
    end
  end
end
