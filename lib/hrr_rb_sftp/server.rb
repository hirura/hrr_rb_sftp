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
    end
  end
end
