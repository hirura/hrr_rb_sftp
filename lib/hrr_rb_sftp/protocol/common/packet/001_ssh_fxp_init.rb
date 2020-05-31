module HrrRbSftp
  class Protocol
    module Common
      class Packet
        class SSH_FXP_INIT < Packet
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
