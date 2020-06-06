module HrrRbSftp
  class Receiver
    def initialize io_in
      @io_in = io_in
    end

    def receive
      begin
        paylaod_length = Protocol::Common::DataType::Uint32.decode(@io_in)
      rescue NoMethodError
        nil
      else
        payload = @io_in.read(paylaod_length)
        if payload.nil? || payload.length != paylaod_length
          nil
        else
          payload
        end
      end
    end
  end
end
