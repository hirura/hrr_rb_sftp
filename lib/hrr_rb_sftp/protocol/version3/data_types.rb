module HrrRbSftp
  class Protocol
    class Version3

      #
      # This module implements SFTP protocol version 3 data types to be used to encode or decode packet.
      #
      module DataTypes
        include Version2::DataTypes
      end
    end
  end
end
