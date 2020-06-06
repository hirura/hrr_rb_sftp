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
        end
      end
    end
  end
end
