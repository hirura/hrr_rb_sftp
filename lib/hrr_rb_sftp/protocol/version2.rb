module HrrRbSftp
  class Protocol
    class Version2
      PROTOCOL_VERSION = 2
    end
  end
end

require "hrr_rb_sftp/protocol/version2/data_type"
require "hrr_rb_sftp/protocol/version2/packet"
