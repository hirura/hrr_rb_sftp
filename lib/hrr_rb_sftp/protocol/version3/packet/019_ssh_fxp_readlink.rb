module HrrRbSftp
  class Protocol
    class Version3
      module Packet
        class SSH_FXP_READLINK
          include Common::Packetable

          TYPE = 19

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
          ]
        end
      end
    end
  end
end
