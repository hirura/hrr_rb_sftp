module HrrRbSftp
  class Protocol
    module Common
      module Packet
        class SSH_FXP_VERSION
          include Packetable

          TYPE = 2

          FORMAT = [
            [DataType::Byte,           :"type"      ],
            [DataType::Uint32,         :"version"   ],
            [DataType::ExtensionPairs, :"extensions"],
          ]
        end
      end
    end
  end
end
