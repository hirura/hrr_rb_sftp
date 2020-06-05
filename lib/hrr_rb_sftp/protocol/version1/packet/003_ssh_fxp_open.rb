module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_OPEN
          include Common::Packetable

          TYPE = 3

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"filename"  ],
            [DataType::Uint32, :"pflags"    ],
            [DataType::Attrs,  :"attrs"     ],
          ]

          SSH_FXF_READ   = 0x00000001
          SSH_FXF_WRITE  = 0x00000002
          SSH_FXF_APPEND = 0x00000004
          SSH_FXF_CREAT  = 0x00000008
          SSH_FXF_TRUNC  = 0x00000010
          SSH_FXF_EXCL   = 0x00000020
        end
      end
    end
  end
end
