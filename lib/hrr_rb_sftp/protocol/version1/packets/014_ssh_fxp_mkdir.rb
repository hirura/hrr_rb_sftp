module HrrRbSftp
  class Protocol
    class Version1
      module Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_MKDIR packet type, format, and responder.
        #
        class SSH_FXP_MKDIR < Packet

          #
          # Represents SSH_FXP_MKDIR packet type.
          #
          TYPE = 14

          #
          # Represents SSH_FXP_MKDIR packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"path"      ],
          ]

          #
          # Responds to SSH_FXP_MKDIR request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_MKDIR request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              log_debug { "Dir.mkdir(#{request[:"path"].inspect})" }
              Dir.mkdir(request[:"path"])
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
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
            rescue Errno::EEXIST => e
              log_debug { e.message }
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => "File exists",
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
