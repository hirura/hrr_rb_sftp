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
          # Private method #conditional_format is used instead.
          #
          # @example
          #   {
          #     :"extended-reply" => {
          #       "hardlink@openssh.com" => [
          #       ],
          #     },
          #   }
          #
          CONDITIONAL_FORMAT = nil

          private

          #
          # Overrides Common::Packetable#conditional_format private method and represents SSH_FXP_EXTENDED_REPLY packet conditional format.
          #
          def conditional_format packet
            packet.inject([]){ |a, (field_name, field_value)|
              a + ((extensions.conditional_reply_format[field_name] || {})[field_value] || [])
            }
          end
        end
      end
    end
  end
end
