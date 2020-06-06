module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_MKDIR
          include Common::Packetable

          TYPE = 14

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
