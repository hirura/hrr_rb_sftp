module HrrRbSftp
  class Protocol
    class Version1
      module Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_STATUS packet type, format, and responder.
        #
        class SSH_FXP_STATUS
          include Common::Packetable

          #
          # Represents SSH_FXP_STATUS packet type.
          #
          TYPE = 101

          #
          # Represents SSH_FXP_STATUS packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::Uint32, :"code"      ],
          ]

          #
          # Represents SSH_FX_OK value.
          #
          SSH_FX_OK                = 0

          #
          # Represents SSH_FX_EOF value.
          #
          SSH_FX_EOF               = 1

          #
          # Represents SSH_FX_NO_SUCH_FILE value.
          #
          SSH_FX_NO_SUCH_FILE      = 2

          #
          # Represents SSH_FX_PERMISSION_DENIED value.
          #
          SSH_FX_PERMISSION_DENIED = 3

          #
          # Represents SSH_FX_FAILURE value.
          #
          SSH_FX_FAILURE           = 4

          #
          # Represents SSH_FX_BAD_MESSAGE value.
          #
          SSH_FX_BAD_MESSAGE       = 5

          #
          # Represents SSH_FX_NO_CONNECTION value.
          #
          SSH_FX_NO_CONNECTION     = 6

          #
          # Represents SSH_FX_CONNECTION_LOST value.
          #
          SSH_FX_CONNECTION_LOST   = 7

          #
          # Represents SSH_FX_OP_UNSUPPORTED value.
          #
          SSH_FX_OP_UNSUPPORTED    = 8
        end
      end
    end
  end
end
