module HrrRbSftp
  class Protocol
    class Version1 < Protocol
      PROTOCOL_VERSION = 1
    end
  end
end

require "hrr_rb_sftp/protocol/version1/data_type"
