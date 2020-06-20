module HrrRbSftp
  class Protocol
    class Version3
      module Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_EXTENDED packet type, format, and responder.
        #
        class SSH_FXP_EXTENDED < Packets::Packet

          #
          # Represents SSH_FXP_EXTENDED packet type.
          #
          TYPE = 200

          #
          # Represents SSH_FXP_EXTENDED packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"            ],
            [DataTypes::Uint32, :"request-id"      ],
            [DataTypes::String, :"extended-request"],
          ]

          #
          # Private method #conditional_format is used instead.
          #
          # @example
          #   {
          #     :"extended-request" => {
          #       "hardlink@openssh.com" => [
          #         [DataTypes::String, :"oldpath"],
          #         [DataTypes::String, :"newpath"],
          #       ],
          #     },
          #   }
          #
          #
          CONDITIONAL_FORMAT = nil

          #
          # Responds to SSH_FXP_EXTENDED request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_EXTENDED request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              if extensions.respond_to? request
                extensions.respond_to request
              else
                {
                  :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_OP_UNSUPPORTED,
                  :"error message" => "Unsupported extended-request: #{request[:"extended-request"]}",
                  :"language tag"  => "",
                }
              end
            rescue => e
              log_error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => e.message,
                :"language tag"  => "",
              }
            end
          end

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
          # Overrides Common::Packetable#conditional_format private method and represents SSH_FXP_EXTENDED packet conditional format.
          #
          def conditional_format packet
            packet.inject([]){ |a, (field_name, field_value)|
              a + ((extensions.conditional_request_format[field_name] || {})[field_value] || [])
            }
          end
        end
      end
    end
  end
end
