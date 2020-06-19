module HrrRbSftp
  class Protocol
    class Version1
      module Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_DATA packet type, format, and responder.
        #
        class SSH_FXP_DATA
          include Common::Packetable

          #
          # Represents SSH_FXP_DATA packet type.
          #
          TYPE = 103

          #
          # Represents SSH_FXP_DATA packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"data"      ],
          ]
        end
      end
    end
  end
end
