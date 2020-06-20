module HrrRbSftp
  class Protocol
    class Version1
      class Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_CLOSE packet type, format, and responder.
        #
        class SSH_FXP_CLOSE < Packet

          #
          # Represents SSH_FXP_CLOSE packet type.
          #
          TYPE = 4

          #
          # Represents SSH_FXP_CLOSE packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"handle"    ],
          ]

          #
          # Responds to SSH_FXP_CLOSE request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_CLOSE request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              raise "Specified handle does not exist" unless handles.has_key?(request[:"handle"])
              handle = request[:"handle"]
              log_debug { "handles[#{handle.inspect}].close" }
              handles[handle].close rescue nil
              log_debug { "handles.delete(#{handle.inspect})" }
              handles.delete(handle)
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
