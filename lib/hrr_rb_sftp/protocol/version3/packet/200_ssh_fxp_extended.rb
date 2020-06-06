module HrrRbSftp
  class Protocol
    class Version3
      module Packet
        class SSH_FXP_EXTENDED
          include Common::Packetable

          TYPE = 200

          FORMAT = [
            [DataType::Byte,   :"type"            ],
            [DataType::Uint32, :"request-id"      ],
            [DataType::String, :"extended-request"],
          ]

          CONDITIONAL_FORMAT = {
            :"extended-request" => {
            },
          }

          def respond_to request
            {
              :"type"          => Packet::SSH_FXP_STATUS::TYPE,
              :"request-id"    => request[:"request-id"],
              :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_OP_UNSUPPORTED,
              :"error message" => "Unsupported extended-request: #{request[:"extended-request"]}",
              :"language tag"  => "",
            }
          end
        end
      end
    end
  end
end
