module HrrRbSftp
  module Protocol
    module Common
      class Packet
        class SSH_FXP_INIT < Packet
          TYPE = 1

          FORMAT = [
            [DataType::Uint32, :"version"],
          ]
        end
      end
    end
  end
end
