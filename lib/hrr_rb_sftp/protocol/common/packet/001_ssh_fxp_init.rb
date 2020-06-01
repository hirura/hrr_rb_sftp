module HrrRbSftp
  class Protocol
    module Common
      module Packet
        class SSH_FXP_INIT
          include Packetable

          TYPE = 1

          FORMAT = [
            [DataType::Byte,   :"type"   ],
            [DataType::Uint32, :"version"],
          ]
        end
      end
    end
  end
end
