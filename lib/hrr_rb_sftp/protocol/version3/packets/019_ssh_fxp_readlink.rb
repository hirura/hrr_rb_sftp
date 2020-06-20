module HrrRbSftp
  class Protocol
    module Version3
      class Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_READLINK packet type, format, and responder.
        #
        class SSH_FXP_READLINK < Packets::Packet

          #
          # Represents SSH_FXP_READLINK packet type.
          #
          TYPE = 19

          #
          # Represents SSH_FXP_READLINK packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"path"      ],
          ]

          #
          # Responds to SSH_FXP_READLINK request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_READLINK request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. In case of success, its type is SSH_FXP_NAME. In other cases, its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              log_debug { "realpath = File.realpath(#{request[:"path"].inspect})" }
              realpath = File.realpath(request[:"path"])
              {
                :"type"        => Packets::SSH_FXP_NAME::TYPE,
                :"request-id"  => request[:"request-id"],
                :"count"       => 1,
                :"filename[0]" => realpath,
                :"longname[0]" => realpath,
                :"attrs[0]"    => {},
              }
            rescue Errno::ENOENT => e
              log_debug { e.message }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
                :"error message" => "No such file or directory",
                :"language tag"  => "",
              }
            rescue Errno::EACCES => e
              log_debug { e.message }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
                :"error message" => "Permission denied",
                :"language tag"  => "",
              }
            rescue => e
              log_error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_FAILURE,
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
