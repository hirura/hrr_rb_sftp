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

          def respond_to request
            begin
              path = request[:"path"]
              attrs = request[:"attrs"]
              FileUtils.chmod(attrs[:"permissions"], path)        if attrs.has_key?(:"permissions")
              File.utime(attrs[:"atime"], attrs[:"mtime"], path)  if attrs.has_key?(:"atime") && attrs.has_key?(:"mtime")
              FileUtils.chown(attrs[:"uid"], attrs[:"gid"], path) if attrs.has_key?(:"uid") && attrs.has_key?(:"gid")
              File.truncate(path, attrs[:"size"])                 if attrs.has_key?(:"size")
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
                :"language tag"  => "",
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
