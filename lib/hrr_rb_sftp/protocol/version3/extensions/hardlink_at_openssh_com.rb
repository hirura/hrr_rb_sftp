module HrrRbSftp
  class Protocol
    class Version3
      class Extensions

        #
        # This class implements hardlink@openssh.com version 1 extension format and responder.
        #
        class HardlinkAtOpensshCom < Extension

          #
          # Represents hardlink@openssh.com version 1 extension name.
          #
          EXTENSION_NAME = "hardlink@openssh.com"

          #
          # Represents hardlink@openssh.com version 1 extension data.
          #
          EXTENSION_DATA = "1"

          #
          # Represents SSH_FXP_EXTENDED packet additional format for hardlink@openssh.com version 1 extension.
          #
          REQUEST_FORMAT = {
            :"extended-request" => {
              "hardlink@openssh.com" => [
                [DataTypes::String, :"oldpath"],
                [DataTypes::String, :"newpath"],
              ],
            },
          }

          #
          # Responds to SSH_FXP_EXTENDED request with hardlink@openssh.com extended-request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_EXTENDED request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              log_debug { "File.link(#{request[:"oldpath"].inspect}, #{request[:"newpath"].inspect})" }
              File.link(request[:"oldpath"], request[:"newpath"])
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
                :"language tag"  => "",
              }
            rescue Errno::ENOENT => e
              log_debug { e.message }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
                :"error message" => "No such file or directory",
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
            end
          end
        end
      end
    end
  end
end

