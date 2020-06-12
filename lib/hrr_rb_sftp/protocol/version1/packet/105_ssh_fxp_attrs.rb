module HrrRbSftp
  class Protocol
    class Version1
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_ATTRS packet type, format, and responder.
        #
        class SSH_FXP_ATTRS
          include Common::Packetable

          #
          # Represents SSH_FXP_ATTRS packet type.
          #
          TYPE = 105

          #
          # Represents SSH_FXP_ATTRS packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::Attrs,  :"attrs"     ],
          ]
        end
      end
    end
  end
end
