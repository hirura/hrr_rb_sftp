module HrrRbSftp
  class Protocol
    class Version2
      module Packet

        #
        # This class implements SFTP protocol version 2 SSH_FXP_RENAME packet type, format, and responder.
        #
        class SSH_FXP_RENAME
          include Common::Packetable

          #
          # Represents SSH_FXP_RENAME packet type.
          #
          TYPE = 18

          #
          # Represents SSH_FXP_RENAME packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"oldpath"   ],
            [DataType::String, :"newpath"   ],
          ]

          #
          # Responds to SSH_FXP_RENAME request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_RENAME request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            oldpath = request[:"oldpath"]
            newpath = request[:"newpath"]
            log_debug { "File.exist?(#{newpath.inspect})" }
            if File.exist?(newpath)
              log_debug { "File exists" }
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => "File exists",
                :"language tag"  => "",
              }
            else
              log_debug { "File does not exist" }
              begin
                log_debug { "File.rename(#{oldpath.inspect}, #{newpath.inspect})" }
                File.rename(oldpath, newpath)
                {
                  :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_OK,
                  :"error message" => "Success",
                  :"language tag"  => "",
                }
              rescue Errno::ENOENT => e
                log_debug { e.message }
                {
                  :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
                  :"error message" => "No such file or directory",
                  :"language tag"  => "",
                }
              rescue Errno::EACCES => e
                log_debug { e.message }
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
end
