module HrrRbSftp
  class Protocol
    class Version1
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_RMDIR packet type, format, and responder.
        #
        class SSH_FXP_RMDIR
          include Common::Packetable

          #
          # Represents SSH_FXP_RMDIR packet type.
          #
          TYPE = 15

          #
          # Represents SSH_FXP_RMDIR packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
          ]

          #
          # Responds to SSH_FXP_RMDIR request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_RMDIR request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              Dir.rmdir request[:"path"]
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
            rescue Errno::ENOTDIR
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => "Not a directory",
                :"language tag"  => "",
              }
            rescue Errno::ENOTEMPTY
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => "Directory not empty",
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
