module HrrRbSftp
  class Protocol
    class Version1
      module Packet

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
          # Represents SSH_FX_OK flag.
          #
          SSH_FX_OK                = 0

          #
          # Represents SSH_FX_EOF flag.
          #
          SSH_FX_EOF               = 1

          #
          # Represents SSH_FX_NO_SUCH_FILE flag.
          #
          SSH_FX_NO_SUCH_FILE      = 2

          #
          # Represents SSH_FX_PERMISSION_DENIED flag.
          #
          SSH_FX_PERMISSION_DENIED = 3

          #
          # Represents SSH_FX_FAILURE flag.
          #
          SSH_FX_FAILURE           = 4

          #
          # Represents SSH_FX_BAD_MESSAGE flag.
          #
          SSH_FX_BAD_MESSAGE       = 5

          #
          # Represents SSH_FX_NO_CONNECTION flag.
          #
          SSH_FX_NO_CONNECTION     = 6

          #
          # Represents SSH_FX_CONNECTION_LOST flag.
          #
          SSH_FX_CONNECTION_LOST   = 7

          #
          # Represents SSH_FX_OP_UNSUPPORTED flag.
          #
          SSH_FX_OP_UNSUPPORTED    = 8
        end
      end
    end
  end
end
