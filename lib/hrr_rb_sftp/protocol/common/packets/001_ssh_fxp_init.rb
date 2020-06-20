module HrrRbSftp
  class Protocol
    module Common
      module Packets

        #
        # This class implements SFTP protocol version independent SSH_FXP_INIT packet type, format, and responder.
        #
        class SSH_FXP_INIT < Packet

          #
          # Represents SSH_FXP_INIT packet type.
          #
          TYPE = 1

          #
          # Represents SSH_FXP_INIT packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"   ],
            [DataTypes::Uint32, :"version"],
          ]
        end
      end
    end
  end
end
