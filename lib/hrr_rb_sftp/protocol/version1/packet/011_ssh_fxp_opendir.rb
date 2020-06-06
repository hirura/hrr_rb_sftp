module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_OPENDIR
          include Common::Packetable

          TYPE = 11

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
          ]

          def respond_to request
            begin
              dir = ::Dir.open(request[:"path"])
              handle = dir.object_id.to_s(16)
              @handles[handle] = dir
              {
                :"type"       => SSH_FXP_HANDLE::TYPE,
                :"request-id" => request[:"request-id"],
                :"handle"     => handle,
              }
            rescue Errno::ENOENT
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
                :"error message" => "No such file or directory",
                :"language tag"  => "",
              }
            rescue Errno::EACCES
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
                :"error message" => "Permission denied",
                :"language tag"  => "",
              }
            rescue Errno::ENOTDIR
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => "Not a directory",
                :"language tag"  => "",
              }
            rescue => e
              log_error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_FAILURE,
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
