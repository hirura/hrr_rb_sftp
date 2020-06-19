module HrrRbSftp
  class Protocol
    module Common

      #
      # This module implements SFTP protocol version common data types to be used to encode or decode packet.
      #
      module DataTypes
      end
    end
  end
end

require "hrr_rb_sftp/protocol/common/data_types/byte"
require "hrr_rb_sftp/protocol/common/data_types/uint32"
require "hrr_rb_sftp/protocol/common/data_types/uint64"
require 'hrr_rb_sftp/protocol/common/data_types/string'
require 'hrr_rb_sftp/protocol/common/data_types/extension_pair'
require 'hrr_rb_sftp/protocol/common/data_types/extension_pairs'
