module HrrRbSftp
  class Protocol
    class Version2 < Protocol
      PROTOCOL_VERSION = 2
    end
  end
end

require "hrr_rb_sftp/protocol/version2/data_type"
require "hrr_rb_sftp/protocol/version2/packet"
