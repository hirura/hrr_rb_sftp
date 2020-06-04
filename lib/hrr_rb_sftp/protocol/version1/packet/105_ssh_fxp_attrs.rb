module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_ATTRS
          include Common::Packetable

          TYPE = 105

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::Attrs,  :"attrs"     ],
          ]
        end
      end
    end
  end
end
