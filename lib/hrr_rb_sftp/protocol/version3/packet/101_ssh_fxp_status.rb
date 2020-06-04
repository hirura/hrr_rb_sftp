module HrrRbSftp
  class Protocol
    class Version3
      module Packet
        class SSH_FXP_STATUS
          include Common::Packetable

          TYPE = 101

          FORMAT = [
            [DataType::Byte,   :"type"         ],
            [DataType::Uint32, :"request-id"   ],
            [DataType::Uint32, :"code"         ],
            [DataType::String, :"error message"],
            [DataType::String, :"language tag" ],
          ]

          SSH_FX_OK                = 0
          SSH_FX_EOF               = 1
          SSH_FX_NO_SUCH_FILE      = 2
          SSH_FX_PERMISSION_DENIED = 3
          SSH_FX_FAILURE           = 4
          SSH_FX_BAD_MESSAGE       = 5
          SSH_FX_NO_CONNECTION     = 6
          SSH_FX_CONNECTION_LOST   = 7
          SSH_FX_OP_UNSUPPORTED    = 8
        end
      end
    end
  end
end
