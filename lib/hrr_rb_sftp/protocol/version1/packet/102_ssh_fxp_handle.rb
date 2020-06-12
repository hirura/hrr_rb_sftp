module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        #
        # This class implements SFTP protocol version 1 SSH_FXP_HANDLE packet type, format, and responder.
        #
        class SSH_FXP_HANDLE
          include Common::Packetable

          #
          # Represents SSH_FXP_HANDLE packet type.
          #
          TYPE = 102

          #
          # Represents SSH_FXP_HANDLE packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
          ]
        end
      end
    end
  end
end
