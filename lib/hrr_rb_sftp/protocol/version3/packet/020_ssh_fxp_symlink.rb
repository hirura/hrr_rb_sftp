module HrrRbSftp
  class Protocol
    class Version3
      module Packet
        class SSH_FXP_SYMLINK
          include Common::Packetable

          TYPE = 20

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"linkpath"  ],
            [DataType::String, :"targetpath"],
          ]
        end
      end
    end
  end
end
