module HrrRbSftp
  class Protocol
    class Version3

      #
      # This module implements SFTP protocol version 3 extension formats and responders.
      #
      module Extension
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version3/extension/hardlink_at_openssh_com"
