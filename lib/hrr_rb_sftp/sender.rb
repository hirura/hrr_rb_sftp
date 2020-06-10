module HrrRbSftp

  #
  # This class implements payload sender.
  #
  class Sender

    #
    # Instantiates a new payload sender for the output IO.
    #
    # @param io_out [IO] An IO for output.
    #
    def initialize io_out
      @io_out = io_out
    end

    #
    # Sends payload_length then payload.
    # Flushes output IO once payload is sent.
    #
    def send payload
      @io_out.write(Protocol::Common::DataType::Uint32.encode(payload.bytesize))
      @io_out.write(payload)
      @io_out.flush
    end
  end
end
