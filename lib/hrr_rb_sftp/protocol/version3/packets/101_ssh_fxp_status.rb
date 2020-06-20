module HrrRbSftp
  class Protocol
    module Version3
      class Packets

        #
        # This class implements SFTP protocol version 3 SSH_FXP_STATUS packet type, format, and responder.
        #
        class SSH_FXP_STATUS < Version2::Packets::SSH_FXP_STATUS

          #
          # Represents SSH_FXP_STATUS packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"         ],
            [DataTypes::Uint32, :"request-id"   ],
            [DataTypes::Uint32, :"code"         ],
            [DataTypes::String, :"error message"],
            [DataTypes::String, :"language tag" ],
          ]
        end
      end
    end
  end
end
