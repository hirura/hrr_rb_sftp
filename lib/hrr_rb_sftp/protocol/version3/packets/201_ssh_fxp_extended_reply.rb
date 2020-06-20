module HrrRbSftp
  class Protocol
    module Version3
      class Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_EXTENDED_REPLY packet type, format, and responder.
        #
        class SSH_FXP_EXTENDED_REPLY < Packets::Packet

          #
          # Represents SSH_FXP_EXTENDED_REPLY packet type.
          #
          TYPE = 201

          #
          # Represents SSH_FXP_EXTENDED_REPLY packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
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
          # Returns An instance of Extensions.
          #
          # @return [Extensions] An instance of Extensions.
          #
          def extensions
            @extensions ||= Protocol.const_get(:"Version#{version}")::Extensions.new(context, logger: logger)
          end

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
