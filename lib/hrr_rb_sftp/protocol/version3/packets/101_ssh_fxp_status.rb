module HrrRbSftp
  class Protocol
    class Version3
      module Packets

        #
        # This class implements SFTP protocol version 3 SSH_FXP_STATUS packet type, format, and responder.
        #
        class SSH_FXP_STATUS < Version1::Packets::SSH_FXP_STATUS

          #
          # Represents SSH_FXP_STATUS packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"         ],
            [DataType::Uint32, :"request-id"   ],
            [DataType::Uint32, :"code"         ],
            [DataType::String, :"error message"],
            [DataType::String, :"language tag" ],
          ]
        end
      end
    end
  end
end
