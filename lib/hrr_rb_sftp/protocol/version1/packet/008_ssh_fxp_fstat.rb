module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_FSTAT
          include Common::Packetable

          TYPE = 8

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
