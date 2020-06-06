module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_OPENDIR
          include Common::Packetable

          TYPE = 11

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
