module HrrRbSftp
  class Protocol
    class Version2
      module Packet
        include Version1::Packet
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version2/packet/018_ssh_fxp_rename"
