module HrrRbSftp
  class Protocol
    class Version2

      #
      # This module implements SFTP protocol version 2 packet types, formats, and responders.
      #
      module Packet
        include Version1::Packet
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version2/packet/018_ssh_fxp_rename"
