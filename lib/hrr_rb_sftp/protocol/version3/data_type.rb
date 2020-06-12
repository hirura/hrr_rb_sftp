module HrrRbSftp
  class Protocol
    class Version3

      #
      # This module implements SFTP protocol version 3 data types to be used to encode or decode packet.
      #
      module DataType
        include Version2::DataType
      end
    end
  end
end
