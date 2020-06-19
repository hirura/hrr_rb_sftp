module HrrRbSftp
  class Protocol
    class Version1

      #
      # This module implements SFTP protocol version 1 data types to be used to encode or decode packet.
      #
      module DataTypes
        include Common::DataTypes
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version1/data_types/attrs"
