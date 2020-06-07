module HrrRbSftp
  class Sender
    def initialize io_out
      @io_out = io_out
    end

    def send payload
      @io_out.write(Protocol::Common::DataType::Uint32.encode(payload.length))
      @io_out.write(payload)
      @io_out.flush
    end
  end
end
