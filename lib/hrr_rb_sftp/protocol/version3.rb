module HrrRbSftp
  class Protocol

    #
    # This class implements SFTP protocol version 3 packet types, formats, and responders.
    #
    class Version3

      #
      # Represents SFTP protocol version 3.
      #
      PROTOCOL_VERSION = 3
    end
  end
end

require "hrr_rb_sftp/protocol/version3/data_type"
require "hrr_rb_sftp/protocol/version3/extensions"
require "hrr_rb_sftp/protocol/version3/packet"
