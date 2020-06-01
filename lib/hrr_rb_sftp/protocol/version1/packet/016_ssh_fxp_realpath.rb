module HrrRbSftp
  class Protocol
    class Version1
      class Packet
        class SSH_FXP_REALPATH < Packet
          TYPE = 16

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
          ]
        end
      end
    end
  end
end
