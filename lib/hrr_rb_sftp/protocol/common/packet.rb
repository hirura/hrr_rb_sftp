module HrrRbSftp
  class Protocol
    module Common
      class Packet
        include Packetable
      end
    end
  end
end

require "hrr_rb_sftp/protocol/common/packet/001_ssh_fxp_init"
require "hrr_rb_sftp/protocol/common/packet/002_ssh_fxp_version"
