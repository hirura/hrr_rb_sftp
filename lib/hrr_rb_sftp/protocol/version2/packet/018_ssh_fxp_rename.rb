module HrrRbSftp
  class Protocol
    class Version2
      module Packet
        class SSH_FXP_RENAME
          include Common::Packetable

          TYPE = 18

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"oldpath"   ],
            [DataType::String, :"newpath"   ],
          ]
        end
      end
    end
  end
end
