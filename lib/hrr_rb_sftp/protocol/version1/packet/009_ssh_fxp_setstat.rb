module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_SETSTAT
          include Common::Packetable

          TYPE = 9

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
            [DataType::Attrs,  :"attrs"     ],
          ]
        end
      end
    end
  end
end
