module HrrRbSftp

  #
  # This module is used to log message with useful logging key.
  #
  # @example
  #   class SomeClass
  #     include HrrRbSftp::Loggable
  #     def initialize logger
  #       self.logger = logger
  #     end
  #     def log_some_info
  #       log_info { "something" }
  #     end
  #   end
  #
  module Loggable

    #
    # A logger instance that has #fatal, #error, #warn, #info, and #debug methods.
    #
    attr_accessor :logger

    #
    # Outputs fatal message when the logger's log level fatal or higher.
    #
    def log_fatal
      if logger
        logger.fatal(log_key){ yield }
      end
    end

    #
    # Outputs error message when the logger's log level error or higher.
    #
    def log_error
      if logger
        logger.error(log_key){ yield }
      end
    end

    #
    # Outputs warn message when the logger's log level warn or higher.
    #
    def log_warn
      if logger
        logger.warn(log_key){ yield }
      end
    end

    #
    # Outputs info message when the logger's log level info or higher.
    #
    def log_info
      if logger
        logger.info(log_key){ yield }
      end
    end

    #
    # Outputs debug message when the logger's log level debug or higher.
    #
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
