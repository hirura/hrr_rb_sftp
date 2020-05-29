module HrrRbSftp
  class Server
    include Loggable

    def initialize logger: nil
      self.logger = logger
    end

    def start _in, _out, _err
      @in  = _in
      @out = _out
      @err = _err
    end
  end
end
