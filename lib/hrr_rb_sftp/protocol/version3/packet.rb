module HrrRbSftp
  class Protocol
    class Version3
      module Packet
        include Version2::Packet
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version3/packet/014_ssh_fxp_mkdir"
require "hrr_rb_sftp/protocol/version3/packet/019_ssh_fxp_readlink"
require "hrr_rb_sftp/protocol/version3/packet/020_ssh_fxp_symlink"
require "hrr_rb_sftp/protocol/version3/packet/101_ssh_fxp_status"
require "hrr_rb_sftp/protocol/version3/packet/200_ssh_fxp_extended"
require "hrr_rb_sftp/protocol/version3/packet/201_ssh_fxp_extended_reply"
