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

          def respond_to request
            oldpath = request[:"oldpath"]
            newpath = request[:"newpath"]
            if File.exist?(newpath)
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => "File exists",
                :"language tag"  => "",
              }
            else
              begin
                File.rename(oldpath, newpath)
                {
                  :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_OK,
                  :"error message" => "Success",
                  :"language tag"  => "",
                }
              rescue Errno::ENOENT
                {
                  :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
                  :"error message" => "No such file or directory",
                  :"language tag"  => "",
                }
              rescue Errno::EACCES
                {
                  :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
                  :"error message" => "Permission denied",
                  :"language tag"  => "",
                }
              rescue => e
                log_error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
                {
                  :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_FAILURE,
                  :"error message" => e.message,
                  :"language tag"  => "",
                }
              end
            end
          end
        end
      end
    end
  end
end
