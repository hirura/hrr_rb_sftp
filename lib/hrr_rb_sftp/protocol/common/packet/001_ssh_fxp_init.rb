module HrrRbSftp
  class Protocol
    module Common
      module Packet

        #
        # This class implements SFTP protocol version independent SSH_FXP_INIT packet type, format, and responder.
        #
        class SSH_FXP_INIT
          include Packetable

          #
          # Represents SSH_FXP_INIT packet type.
          #
          TYPE = 1

          #
          # Represents SSH_FXP_INIT packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"   ],
            [DataType::Uint32, :"version"],
          ]
        end
      end
    end
  end
end
