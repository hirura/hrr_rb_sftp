module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_CLOSE
          include Common::Packetable

          TYPE = 4

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
          ]

          def close_and_delete_handle handle
            @handles[handle].close rescue nil
            @handles.delete(handle)
          end

          def respond_to request
            begin
              if close_and_delete_handle(request[:"handle"])
                {
                  :"type"          => SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => SSH_FXP_STATUS::SSH_FX_OK,
                  :"error message" => "Success",
                  :"language tag"  => "",
                }
              else
                {
                  :"type"          => SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => SSH_FXP_STATUS::SSH_FX_FAILURE,
                  :"error message" => "Specified handle does not exist",
                  :"language tag"  => "",
                }
              end
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
