module HrrRbSftp
  class Protocol

    #
    # This class implements SFTP protocol version 1 packet types, formats, and responders.
    #
    class Version1

      #
      # Represents SFTP protocol version 1.
      #
      PROTOCOL_VERSION = 1
    end
  end
end

require "hrr_rb_sftp/protocol/version1/data_type"
require "hrr_rb_sftp/protocol/version1/packet"
