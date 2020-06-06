module HrrRbSftp
  class Protocol
    class Version3
      module Packet
        class SSH_FXP_EXTENDED_REPLY
          include Common::Packetable

          TYPE = 201

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
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
