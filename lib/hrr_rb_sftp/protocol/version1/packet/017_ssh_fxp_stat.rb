module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_STAT
          include Common::Packetable

          TYPE = 17

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
