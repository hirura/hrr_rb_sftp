module HrrRbSftp
  class Protocol
    class Version1
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_SETSTAT packet type, format, and responder.
        #
        class SSH_FXP_SETSTAT
          include Common::Packetable

          #
          # Represents SSH_FXP_SETSTAT packet type.
          #
          TYPE = 9

          #
          # Represents SSH_FXP_SETSTAT packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
            [DataType::Attrs,  :"attrs"     ],
          ]

          #
          # Responds to SSH_FXP_SETSTAT request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_SETSTAT request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              path = request[:"path"]
              attrs = request[:"attrs"]
              File.truncate(path, attrs[:"size"])                 if attrs.has_key?(:"size")
              FileUtils.chmod(attrs[:"permissions"], path)        if attrs.has_key?(:"permissions")
              File.utime(attrs[:"atime"], attrs[:"mtime"], path)  if attrs.has_key?(:"atime") && attrs.has_key?(:"mtime")
              FileUtils.chown(attrs[:"uid"], attrs[:"gid"], path) if attrs.has_key?(:"uid") && attrs.has_key?(:"gid")
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
            rescue Errno::EACCES, Errno::EPERM
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
