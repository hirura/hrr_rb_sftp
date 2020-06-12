module HrrRbSftp
  class Protocol
    class Version3
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_READLINK packet type, format, and responder.
        #
        class SSH_FXP_READLINK
          include Common::Packetable

          #
          # Represents SSH_FXP_READLINK packet type.
          #
          TYPE = 19

          #
          # Represents SSH_FXP_READLINK packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
          ]

          #
          # Responds to SSH_FXP_READLINK request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_READLINK request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. In case of success, its type is SSH_FXP_NAME. In other cases, its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              {
                :"type"        => Packet::SSH_FXP_NAME::TYPE,
                :"request-id"  => request[:"request-id"],
                :"count"       => 1,
                :"filename[0]" => File.realpath(request[:"path"]),
                :"longname[0]" => File.realpath(request[:"path"]),
                :"attrs[0]"    => {},
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
