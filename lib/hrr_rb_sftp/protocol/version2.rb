module HrrRbSftp
  class Protocol

    #
    # This class implements SFTP protocol version 2 packet types, formats, and responders.
    #
    class Version2

      #
      # Represents SFTP protocol version 2.
      #
      PROTOCOL_VERSION = 2
    end
  end
end

require "hrr_rb_sftp/protocol/version2/data_type"
require "hrr_rb_sftp/protocol/version2/packets"
