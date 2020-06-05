module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_HANDLE
          include Common::Packetable

          TYPE = 102

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
