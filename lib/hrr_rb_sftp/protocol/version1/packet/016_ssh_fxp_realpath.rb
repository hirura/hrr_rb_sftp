module HrrRbSftp
  class Protocol
    class Version1
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_REALPATH packet type, format, and responder.
        #
        class SSH_FXP_REALPATH
          include Common::Packetable

          #
          # Represents SSH_FXP_REALPATH packet type.
          #
          TYPE = 16

          #
          # Represents SSH_FXP_REALPATH packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
          ]

          #
          # Responds to SSH_FXP_REALPATH request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_REALPATH request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_NAME.
          #
          def respond_to request
            {
              :"type"        => SSH_FXP_NAME::TYPE,
              :"request-id"  => request[:"request-id"],
              :"count"       => 1,
              :"filename[0]" => File.absolute_path(request[:"path"]),
              :"longname[0]" => File.absolute_path(request[:"path"]),
              :"attrs[0]"    => {},
            }
          end
        end
      end
    end
  end
end
