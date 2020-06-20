module HrrRbSftp
  class Protocol
    module Version3

      #
      # This class implements SFTP protocol version 3 packet types, formats, and responders.
      #
      class Packets < Version2::Packets
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version3/packets/014_ssh_fxp_mkdir"
require "hrr_rb_sftp/protocol/version3/packets/019_ssh_fxp_readlink"
require "hrr_rb_sftp/protocol/version3/packets/020_ssh_fxp_symlink"
require "hrr_rb_sftp/protocol/version3/packets/101_ssh_fxp_status"
require "hrr_rb_sftp/protocol/version3/packets/200_ssh_fxp_extended"
require "hrr_rb_sftp/protocol/version3/packets/201_ssh_fxp_extended_reply"
