module HrrRbSftp
  class Protocol
    class Version3
      class Extensions

        #
        # This class implements posix-rename@openssh.com version 1 extension format and responder.
        #
        class PosixRenameAtOpensshCom
          include Common::Extensionable

          #
          # Represents posix-rename@openssh.com version 1 extension name.
          #
          EXTENSION_NAME = "posix-rename@openssh.com"

          #
          # Represents posix-rename@openssh.com version 1 extension data.
          #
          EXTENSION_DATA = "1"

          #
          # Represents SSH_FXP_EXTENDED packet additional format for posix-rename@openssh.com version 1 extension.
          #
          REQUEST_FORMAT = {
            :"extended-request" => {
              "posix-rename@openssh.com" => [
                [DataType::String, :"oldpath"],
                [DataType::String, :"newpath"],
              ],
            },
          }

          #
          # Responds to SSH_FXP_EXTENDED request with posix-rename@openssh.com extended-request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_EXTENDED request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              oldpath = request[:"oldpath"]
              newpath = request[:"newpath"]
              log_debug { "File.rename(#{oldpath.inspect}, #{newpath.inspect})" }
              File.rename(oldpath, newpath)
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
            end
          end
        end
      end
    end
  end
end
