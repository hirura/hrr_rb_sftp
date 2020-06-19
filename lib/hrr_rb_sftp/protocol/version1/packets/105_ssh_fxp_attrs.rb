module HrrRbSftp
  class Protocol
    class Version1
      module Packets

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
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::Attrs,  :"attrs"     ],
          ]
        end
      end
    end
  end
end
