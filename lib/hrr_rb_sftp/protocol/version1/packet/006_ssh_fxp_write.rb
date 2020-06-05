module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_WRITE
          include Common::Packetable

          TYPE = 6

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
            [DataType::Uint64, :"offset"    ],
            [DataType::String, :"data"      ],
          ]
        end
      end
    end
  end
end
