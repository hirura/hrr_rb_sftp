module HrrRbSftp
  class Protocol
    module Common
      class Packet
        class SSH_FXP_VERSION < Packet
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
