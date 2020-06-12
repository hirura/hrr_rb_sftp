module HrrRbSftp
  class Protocol
    class Version1
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_WRITE packet type, format, and responder.
        #
        class SSH_FXP_WRITE
          include Common::Packetable

          #
          # Represents SSH_FXP_WRITE packet type.
          #
          TYPE = 6

          #
          # Represents SSH_FXP_WRITE packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
            [DataType::Uint64, :"offset"    ],
            [DataType::String, :"data"      ],
          ]

          #
          # Responds to SSH_FXP_WRITE request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_WRITE request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              raise "Specified handle does not exist" unless @handles.has_key?(request[:"handle"])
              file = @handles[request[:"handle"]]
              file.pos = request[:"offset"]
              file.write request[:"data"]
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
