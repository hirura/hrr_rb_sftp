module HrrRbSftp
  class Protocol

    #
    # This module implements SFTP protocol version independent common functions.
    #
    module Common
    end
  end
end

require "hrr_rb_sftp/protocol/common/data_type"
require "hrr_rb_sftp/protocol/common/packetable"
require "hrr_rb_sftp/protocol/common/extensionable"
require "hrr_rb_sftp/protocol/common/packet"
