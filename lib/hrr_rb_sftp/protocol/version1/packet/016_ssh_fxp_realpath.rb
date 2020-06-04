module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_REALPATH
          include Common::Packetable

          TYPE = 16

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
          ]

          def respond_to request
            {
              :"type"        => SSH_FXP_NAME::TYPE,
              :"request-id"  => request[:"request-id"],
              :"count"       => 1,
              :"filename[0]" => File.absolute_path(request[:"path"]),
              :"longname[0]" => File.absolute_path(request[:"path"]),
              :"attrs[0]"    => {},
            }
          end
        end
      end
    end
  end
end
