module HrrRbSftp
  class Protocol
    class Version3
      class Extensions

        #
        # This class implements fsync@openssh.com version 1 extension format and responder.
        #
        class FsyncAtOpensshCom
          include Common::Extensionable

          #
          # Represents fsync@openssh.com version 1 extension name.
          #
          EXTENSION_NAME = "fsync@openssh.com"

          #
          # Represents fsync@openssh.com version 1 extension data.
          #
          EXTENSION_DATA = "1"

          #
          # Represents SSH_FXP_EXTENDED packet additional format for fsync@openssh.com version 1 extension.
          #
          REQUEST_FORMAT = {
            :"extended-request" => {
              "fsync@openssh.com" => [
                [DataType::String, :"handle"],
              ],
            },
          }

          #
          # Responds to SSH_FXP_EXTENDED request with fsync@openssh.com extended-request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_EXTENDED request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              raise "Specified handle does not exist" unless handles.has_key?(request[:"handle"])
              log_debug { "file = handles[#{request[:"handle"].inspect}]" }
              file = handles[request[:"handle"]]
              log_debug { "file.fsync" }
              file.fsync
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
                :"language tag"  => "",
              }
            end
          end
        end
      end
    end
  end
end

