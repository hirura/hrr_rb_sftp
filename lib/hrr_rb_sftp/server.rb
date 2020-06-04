module HrrRbSftp
  class Server
    include Loggable

    def initialize logger: nil
      self.logger = logger
    end

    def start io_in, io_out, io_err
      @io_in  = io_in
      @io_out = io_out
      @io_err = io_err

      @receiver = Receiver.new(@io_in)
      @sender   = Sender.new(@io_out)

      negotiate_version
      respond_to_requests
    end

    private

    def negotiate_version
      remote_version = receive_fxp_init
      @version = [remote_version, Protocol.versions.max].min
      send_fxp_version
    end

    def receive_fxp_init
      payload = @receiver.receive
      packet = Protocol::Common::Packet::SSH_FXP_INIT.new(logger: logger).decode payload
      packet[:"version"]
    end

    def send_fxp_version
      packet = {
        :"type"       => Protocol::Common::Packet::SSH_FXP_VERSION::TYPE,
        :"version"    => @version,
        :"extensions" => [],
      }
      payload = Protocol::Common::Packet::SSH_FXP_VERSION.new(logger: logger).encode packet
      @sender.send payload
    end

    def respond_to_requests
      protocol = Protocol.new(@version, logger: logger)
      while true
        request = @receiver.receive
        response = protocol.respond_to request
        @sender.send response
      end
    end
  end
end
