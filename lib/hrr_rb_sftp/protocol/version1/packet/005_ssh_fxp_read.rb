module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_READ
          include Common::Packetable

          TYPE = 5

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
            [DataType::Uint64, :"offset"    ],
            [DataType::Uint32, :"len"       ],
          ]
        end
      end
    end
  end
end
