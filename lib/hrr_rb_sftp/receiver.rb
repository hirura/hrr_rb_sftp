module HrrRbSftp

  #
  # This class implements payload receiver.
  #
  class Receiver

    #
    # Instantiates a new payload receiver for the input IO.
    #
    # @param io_in [IO] An IO for input.
    #
    def initialize io_in
      @io_in = io_in
    end

    #
    # Receives payload_length payload. When input IO is EOF, returns nil.
    #
    # @return [String, nil] Received payload. when input IO is EOF, retruns nil.
    #
    def receive
      begin
        paylaod_length = Protocol::Common::DataType::Uint32.decode(@io_in)
      rescue NoMethodError
        nil
      else
        payload = @io_in.read(paylaod_length)
        if payload.nil? || payload.bytesize != paylaod_length
          nil
        else
          payload
        end
      end
    end
  end
end
