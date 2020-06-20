module HrrRbSftp
  class Protocol
    module Common
      module Packets

        #
        # This class implements SFTP protocol version independent SSH_FXP_VERSION packet type, format, and responder.
        #
        class SSH_FXP_VERSION < Packet

          #
          # Represents SSH_FXP_VERSION packet type.
          #
          TYPE = 2

          #
          # Represents SSH_FXP_VERSION packet format.
          #
          FORMAT = [
            [DataTypes::Byte,           :"type"      ],
            [DataTypes::Uint32,         :"version"   ],
            [DataTypes::ExtensionPairs, :"extensions"],
          ]
        end
      end
    end
  end
end
