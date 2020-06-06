module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_FSETSTAT
          include Common::Packetable

          TYPE = 10

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
            [DataType::Attrs,  :"attrs"     ],
          ]

          def respond_to request
            begin
              raise "Specified handle does not exist" unless @handles.has_key?(request[:"handle"])
              file = @handles[request[:"handle"]]
              attrs = request[:"attrs"]
              file.chmod(attrs[:"permissions"])                       if attrs.has_key?(:"permissions")
              File.utime(attrs[:"atime"], attrs[:"mtime"], file.path) if attrs.has_key?(:"atime") && attrs.has_key?(:"mtime")
              file.chown(attrs[:"uid"], attrs[:"gid"])                if attrs.has_key?(:"uid") && attrs.has_key?(:"gid")
              file.truncate(attrs[:"size"])                           if attrs.has_key?(:"size")
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
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
