module HrrRbSftp
  class Protocol
    module Version1
      class Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_READ packet type, format, and responder.
        #
        class SSH_FXP_READ < Packet

          #
          # Represents SSH_FXP_READ packet type.
          #
          TYPE = 5

          #
          # Represents SSH_FXP_READ packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"handle"    ],
            [DataTypes::Uint64, :"offset"    ],
            [DataTypes::Uint32, :"len"       ],
          ]

          #
          # Responds to SSH_FXP_READ request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_READ request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. In case of success, its type is SSH_FXP_DATA. In other cases, its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              raise "Specified handle does not exist" unless handles.has_key?(request[:"handle"])
              log_debug { "file = handles[#{request[:"handle"].inspect}]" }
              file = handles[request[:"handle"]]
              log_debug { "file.pos = #{request[:"offset"].inspect}" }
              file.pos = request[:"offset"]
              unless file.eof?
                log_debug { "data = file.read(#{request[:"len"].inspect})" }
                data = file.read(request[:"len"])
                {
                  :"type"          => SSH_FXP_DATA::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"data"          => data,
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
