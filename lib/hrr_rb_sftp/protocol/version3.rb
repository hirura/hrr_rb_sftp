module HrrRbSftp
  class Protocol

    #
    # This module implements SFTP protocol version 3 packet types, formats, and responders.
    #
    module Version3

      #
      # Represents SFTP protocol version 3.
      #
      PROTOCOL_VERSION = 3
    end
  end
end

require "hrr_rb_sftp/protocol/version3/data_types"
require "hrr_rb_sftp/protocol/version3/extensions"
require "hrr_rb_sftp/protocol/version3/packets"
