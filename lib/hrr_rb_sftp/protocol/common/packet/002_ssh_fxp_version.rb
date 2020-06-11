module HrrRbSftp
  class Protocol
    module Common
      module Packet

        #
        # This class implements SFTP protocol version independent SSH_FXP_VERSION packet type, format, and responder.
        #
        class SSH_FXP_VERSION
          include Packetable

          #
          # Represents SSH_FXP_VERSION packet type.
          #
          TYPE = 2

          #
          # Represents SSH_FXP_VERSION packet format.
          #
          FORMAT = [
            [DataType::Byte,           :"type"      ],
            [DataType::Uint32,         :"version"   ],
            [DataType::ExtensionPairs, :"extensions"],
          ]
        end
      end
    end
  end
end
