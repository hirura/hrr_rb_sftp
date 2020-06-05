module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_DATA
          include Common::Packetable

          TYPE = 103

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"data"      ],
          ]
        end
      end
    end
  end
end
