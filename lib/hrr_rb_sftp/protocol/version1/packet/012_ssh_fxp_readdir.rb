module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_READDIR
          include Common::Packetable

          TYPE = 12

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
          ]
        end
      end
    end
  end
end
