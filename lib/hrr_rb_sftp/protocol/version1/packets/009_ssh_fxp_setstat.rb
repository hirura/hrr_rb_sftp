module HrrRbSftp
  class Protocol
    class Version1
      module Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_SETSTAT packet type, format, and responder.
        #
        class SSH_FXP_SETSTAT < Packet

          #
          # Represents SSH_FXP_SETSTAT packet type.
          #
          TYPE = 9

          #
          # Represents SSH_FXP_SETSTAT packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"path"      ],
            [DataTypes::Attrs,  :"attrs"     ],
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
              if attrs.has_key?(:"size")
                log_debug { "File.truncate(#{path.inspect}, #{attrs[:"size"].inspect})" }
                File.truncate(path, attrs[:"size"])
              end
              if attrs.has_key?(:"permissions")
                log_debug { "File.chmod(#{attrs[:"permissions"].inspect}, #{path.inspect})" }
                File.chmod(attrs[:"permissions"], path)
              end
              if attrs.has_key?(:"atime") && attrs.has_key?(:"mtime")
                log_debug { "File.utime(#{attrs[:"atime"].inspect}, #{attrs[:"mtime"].inspect}, #{path.inspect})" }
                File.utime(attrs[:"atime"], attrs[:"mtime"], path)
              end
              if attrs.has_key?(:"uid") && attrs.has_key?(:"gid")
                log_debug { "File.chown(#{attrs[:"uid"].inspect}, #{attrs[:"gid"].inspect}, #{path.inspect})" }
                File.chown(attrs[:"uid"], attrs[:"gid"], path)
              end
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
                :"language tag"  => "",
              }
            rescue Errno::ENOENT => e
              log_debug { e.message }
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
                :"error message" => "No such file or directory",
                :"language tag"  => "",
              }
            rescue Errno::EACCES, Errno::EPERM => e
              log_debug { e.message }
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
