module HrrRbSftp
  module Loggable
    attr_accessor :logger

    def log_fatal
      if logger
        logger.fatal(log_key){ yield }
      end
    end

    def log_error
      if logger
        logger.error(log_key){ yield }
      end
    end

    def log_warn
      if logger
        logger.warn(log_key){ yield }
      end
    end

    def log_info
      if logger
        logger.info(log_key){ yield }
      end
    end

    def log_debug
      if logger
        logger.debug(log_key){ yield }
      end
    end

    private

    def log_key
      @log_key ||= self.class.to_s + "[%x]" % object_id
    end
  end
end
