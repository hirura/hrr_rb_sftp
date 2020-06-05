module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_READ
          include Common::Packetable

          TYPE = 5

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
            [DataType::Uint64, :"offset"    ],
            [DataType::Uint32, :"len"       ],
          ]

          def respond_to request
            begin
              raise "Specified handle does not exist" unless @handles.has_key?(request[:"handle"])
              file = @handles[request[:"handle"]]
              file.pos = request[:"offset"]
              unless file.eof?
                {
                  :"type"          => SSH_FXP_DATA::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"data"          => file.read(request[:"len"]),
                }
              else
                {
                  :"type"          => SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => SSH_FXP_STATUS::SSH_FX_EOF,
                  :"error message" => "End of file",
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
