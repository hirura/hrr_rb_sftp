module HrrRbSftp
  class Receiver
    def initialize io_in
      @io_in = io_in
    end

    def receive
      paylaod_length = Protocol::Common::DataType::Uint32.decode(@io_in)
      @io_in.read(paylaod_length)
    end
  end
end
