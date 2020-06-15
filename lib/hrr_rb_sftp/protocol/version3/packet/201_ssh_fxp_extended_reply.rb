module HrrRbSftp
  class Protocol
    class Version3
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_EXTENDED_REPLY packet type, format, and responder.
        #
        class SSH_FXP_EXTENDED_REPLY
          include Common::Packetable

          #
          # Represents SSH_FXP_EXTENDED_REPLY packet type.
          #
          TYPE = 201

          #
          # Represents SSH_FXP_EXTENDED_REPLY packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
          ]

          #
          # Represents SSH_FXP_EXTENDED_REPLY packet conditional format.
          #
          # @example
          #   {
          #     :"extended-reply" => {
          #       "hardlink@openssh.com" => [
          #       ],
          #     },
          #   }
          #
          CONDITIONAL_FORMAT = Extension.conditional_reply_format
        end
      end
    end
  end
end
