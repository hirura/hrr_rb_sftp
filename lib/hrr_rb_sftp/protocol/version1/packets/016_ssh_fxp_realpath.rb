module HrrRbSftp
  class Protocol
    module Version1
      class Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_REALPATH packet type, format, and responder.
        #
        class SSH_FXP_REALPATH < Packet

          #
          # Represents SSH_FXP_REALPATH packet type.
          #
          TYPE = 16

          #
          # Represents SSH_FXP_REALPATH packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"path"      ],
          ]

          #
          # Responds to SSH_FXP_REALPATH request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_REALPATH request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_NAME.
          #
          def respond_to request
            log_debug { "absolute_path = File.absolute_path(#{request[:"path"].inspect})" }
            absolute_path = File.absolute_path(request[:"path"])
            {
              :"type"        => SSH_FXP_NAME::TYPE,
              :"request-id"  => request[:"request-id"],
              :"count"       => 1,
              :"filename[0]" => absolute_path,
              :"longname[0]" => absolute_path,
              :"attrs[0]"    => {},
            }
          end
        end
      end
    end
  end
end
