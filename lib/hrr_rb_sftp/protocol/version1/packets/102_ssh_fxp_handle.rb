module HrrRbSftp
  class Protocol
    class Version1
      module Packets
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
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"handle"    ],
          ]
        end
      end
    end
  end
end
