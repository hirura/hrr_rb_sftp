module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_REMOVE
          include Common::Packetable

          TYPE = 13

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"filename"  ],
          ]
        end
      end
    end
  end
end
