module HrrRbSftp
  class Protocol
    class Version1
      module Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_OPENDIR packet type, format, and responder.
        #
        class SSH_FXP_OPENDIR < Packet

          #
          # Represents SSH_FXP_OPENDIR packet type.
          #
          TYPE = 11

          #
          # Represents SSH_FXP_OPENDIR packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"path"      ],
          ]

          #
          # Responds to SSH_FXP_OPENDIR request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_OPENDIR request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. In case of success, its type is SSH_FXP_HANDLE. In other cases, its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              log_debug { "dir = Dir.open(#{request[:"path"].inspect})" }
              dir = ::Dir.open(request[:"path"])
              log_debug { "handle = #{dir.object_id.to_s(16).inspect}" }
              handle = dir.object_id.to_s(16)
              log_debug { "handles[#{handle.inspect}] = dir" }
              handles[handle] = dir
              {
                :"type"       => SSH_FXP_HANDLE::TYPE,
                :"request-id" => request[:"request-id"],
                :"handle"     => handle,
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
            rescue Errno::EACCES => e
              log_debug { e.message }
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
                :"error message" => "Permission denied",
                :"language tag"  => "",
              }
            rescue Errno::ENOTDIR => e
              log_debug { e.message }
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
