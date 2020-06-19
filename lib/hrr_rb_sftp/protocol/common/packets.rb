module HrrRbSftp
  class Protocol
    module Common

      #
      # This module implements SFTP protocol version independent packet types, formats, and responders.
      #
      module Packets
      end
    end
  end
end

require "hrr_rb_sftp/protocol/common/packets/001_ssh_fxp_init"
require "hrr_rb_sftp/protocol/common/packets/002_ssh_fxp_version"
