module HrrRbSftp
  class Protocol
    class Version3
      PROTOCOL_VERSION = 3
    end
  end
end

require "hrr_rb_sftp/protocol/version3/data_type"
require "hrr_rb_sftp/protocol/version3/packet"
