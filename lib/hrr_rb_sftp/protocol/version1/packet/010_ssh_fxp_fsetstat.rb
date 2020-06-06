module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_FSETSTAT
          include Common::Packetable

          TYPE = 10

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
            [DataType::Attrs,  :"attrs"     ],
          ]
        end
      end
    end
  end
end
