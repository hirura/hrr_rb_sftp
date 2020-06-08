module HrrRbSftp
  class Server
    include Loggable

    def initialize logger: nil
      self.logger = logger
    end

    def start io_in, io_out, io_err=nil
      log_info { "start server" }

      @io_in  = io_in
      @io_out = io_out
      @io_err = io_err

      @receiver = Receiver.new(@io_in)
      @sender   = Sender.new(@io_out)

      @version = negotiate_version

      @protocol = Protocol.new(@version, logger: logger)

      begin
        respond_to_requests
      rescue => e
        log_error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
        raise
      ensure
        close_handles
      end

      log_info { "server finished" }
    end

    private

    def negotiate_version
      log_info { "start negotiate_version" }

      remote_version = receive_fxp_init
      log_info { "remote version: #{remote_version}" }

      local_version = Protocol.versions.max
      log_info { "local version: #{local_version}" }

      version = [remote_version, local_version].min
      log_info { "negotiated version: #{version}" }

      send_fxp_version version

      version
    end

    def receive_fxp_init
      log_debug { "start receive_fxp_init" }

      payload = @receiver.receive

      if payload.nil?
        raise "Failed receiving SSH_FXP_INIT"
      end

      packet = Protocol::Common::Packet::SSH_FXP_INIT.new({}, logger: logger).decode payload
      packet[:"version"]
    end

    def send_fxp_version version
      log_debug { "start send_fxp_version" }

      packet = {
        :"type"       => Protocol::Common::Packet::SSH_FXP_VERSION::TYPE,
        :"version"    => version,
        :"extensions" => [],
      }
      payload = Protocol::Common::Packet::SSH_FXP_VERSION.new({}, logger: logger).encode packet
      @sender.send payload
    end

    def respond_to_requests
      log_info { "start respond_to_requests" }

      log_info { "start request and response loop" }
      while request = @receiver.receive
        response = @protocol.respond_to request
        @sender.send response
      end
      log_info { "request and response loop finished" }
    end

    def close_handles
      log_info { "closing handles" }
      @protocol.close_handles
      log_info { "handles closed" }
    end
  end
end
