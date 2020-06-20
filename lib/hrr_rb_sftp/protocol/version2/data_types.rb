module HrrRbSftp
  class Protocol
    module Version2

      #
      # This module implements SFTP protocol version 2 data types to be used to encode or decode packet.
      #
      module DataTypes
        include Version1::DataTypes
      end
    end
  end
end
