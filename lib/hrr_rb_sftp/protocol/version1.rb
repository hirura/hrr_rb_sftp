module HrrRbSftp
  class Protocol

    #
    # This module implements SFTP protocol version 1 packet types, formats, and responders.
    #
    module Version1

      #
      # Represents SFTP protocol version 1.
      #
      PROTOCOL_VERSION = 1
    end
  end
end

require "hrr_rb_sftp/protocol/version1/data_types"
require "hrr_rb_sftp/protocol/version1/packets"
