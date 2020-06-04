module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        def self.list
          constants.select{|c| c.to_s.start_with?("SSH_FXP_")}.map{|c| const_get(c)}
        end
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version1/packet/016_ssh_fxp_realpath"
require "hrr_rb_sftp/protocol/version1/packet/017_ssh_fxp_stat"
require "hrr_rb_sftp/protocol/version1/packet/101_ssh_fxp_status"
require "hrr_rb_sftp/protocol/version1/packet/104_ssh_fxp_name"
