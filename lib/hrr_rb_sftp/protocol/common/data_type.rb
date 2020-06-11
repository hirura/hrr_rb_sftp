module HrrRbSftp
  class Protocol
    module Common

      #
      # This module implements SFTP protocol version common data types to be used to encode or decode packet.
      #
      module DataType
      end
    end
  end
end

require "hrr_rb_sftp/protocol/common/data_type/byte"
require "hrr_rb_sftp/protocol/common/data_type/uint32"
require "hrr_rb_sftp/protocol/common/data_type/uint64"
require 'hrr_rb_sftp/protocol/common/data_type/string'
require 'hrr_rb_sftp/protocol/common/data_type/extension_pair'
require 'hrr_rb_sftp/protocol/common/data_type/extension_pairs'
