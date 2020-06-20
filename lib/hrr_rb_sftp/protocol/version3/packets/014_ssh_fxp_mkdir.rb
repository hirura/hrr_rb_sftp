module HrrRbSftp
  class Protocol
    module Version3
      class Packets

        #
        # This class implements SFTP protocol version 3 SSH_FXP_MKDIR packet type, format, and responder.
        #
        class SSH_FXP_MKDIR < Version2::Packets::SSH_FXP_MKDIR

          #
          # Represents SSH_FXP_MKDIR packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"path"      ],
            [DataTypes::Attrs,  :"attrs"     ],
          ]

          #
          # Responds to SSH_FXP_MKDIR request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_MKDIR request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              args = [request[:"path"]]
              if request[:"attrs"].has_key?(:"permissions")
                args.push request[:"attrs"][:"permissions"]
              end
              log_debug { "Dir.mkdir(#{args.map(&:inspect).join(", ")})" }
              Dir.mkdir(*args)
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
                :"language tag"  => "",
              }
            rescue Errno::EACCES => e
              log_debug { e.message }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
                :"error message" => "Permission denied",
                :"language tag"  => "",
              }
            rescue Errno::EEXIST => e
              log_debug { e.message }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => "File exists",
                :"language tag"  => "",
              }
            rescue => e
              log_error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_FAILURE,
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
