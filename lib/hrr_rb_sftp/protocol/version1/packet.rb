module HrrRbSftp
  class Protocol
    class Version1
      module Packet
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version1/packet/003_ssh_fxp_open"
require "hrr_rb_sftp/protocol/version1/packet/004_ssh_fxp_close"
require "hrr_rb_sftp/protocol/version1/packet/016_ssh_fxp_realpath"
require "hrr_rb_sftp/protocol/version1/packet/017_ssh_fxp_stat"
require "hrr_rb_sftp/protocol/version1/packet/101_ssh_fxp_status"
require "hrr_rb_sftp/protocol/version1/packet/102_ssh_fxp_handle"
require "hrr_rb_sftp/protocol/version1/packet/104_ssh_fxp_name"
require "hrr_rb_sftp/protocol/version1/packet/105_ssh_fxp_attrs"
