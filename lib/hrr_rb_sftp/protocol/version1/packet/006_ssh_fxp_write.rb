module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_WRITE
          include Common::Packetable

          TYPE = 6

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
            [DataType::Uint64, :"offset"    ],
            [DataType::String, :"data"      ],
          ]

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
