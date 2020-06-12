module HrrRbSftp
  class Protocol
    class Version2

      #
      # This module implements SFTP protocol version 2 data types to be used to encode or decode packet.
      #
      module DataType
        include Version1::DataType
      end
    end
  end
end
