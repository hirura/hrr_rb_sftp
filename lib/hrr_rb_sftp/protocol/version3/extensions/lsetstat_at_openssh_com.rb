module HrrRbSftp
  class Protocol
    class Version3
      class Extensions

        #
        # This class implements lsetstat@openssh.com version 1 extension format and responder.
        #
        class LsetstatAtOpensshCom
          include Common::Extensionable

          #
          # Represents lsetstat@openssh.com version 1 extension name.
          #
          EXTENSION_NAME = "lsetstat@openssh.com"

          #
          # Represents lsetstat@openssh.com version 1 extension data.
          #
          EXTENSION_DATA = "1"

          #
          # Represents SSH_FXP_EXTENDED packet additional format for lsetstat@openssh.com version 1 extension.
          #
          REQUEST_FORMAT = {
            :"extended-request" => {
              "lsetstat@openssh.com" => [
                [DataTypes::String, :"path" ],
                [DataTypes::Attrs,  :"attrs"],
              ],
            },
          }

          #
          # Responds to SSH_FXP_EXTENDED request with lsetstat@openssh.com extended-request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_EXTENDED request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              path = request[:"path"]
              attrs = request[:"attrs"]
              raise BadMessageError, "Invalid file attribute: size" if attrs.has_key?(:"size")
              if attrs.has_key?(:"atime") && attrs.has_key?(:"mtime")
                raise FileLutimeUnsupportedError, "File.lutime is not supported on this Ruby version" unless File.respond_to?(:lutime)
                log_debug { "File.lutime(#{attrs[:"atime"].inspect}, #{attrs[:"mtime"].inspect}, #{path.inspect})" }
                File.lutime(attrs[:"atime"], attrs[:"mtime"], path)
              end
              if attrs.has_key?(:"uid") && attrs.has_key?(:"gid")
                log_debug { "File.lchown(#{attrs[:"uid"].inspect}, #{attrs[:"gid"].inspect}, #{path.inspect})" }
                File.lchown(attrs[:"uid"], attrs[:"gid"], path)
              end
              if attrs.has_key?(:"permissions")
                log_debug { "File.lchmod(#{attrs[:"permissions"].inspect}, #{path.inspect})" }
                File.lchmod(attrs[:"permissions"], path)
              end
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
                :"language tag"  => "",
              }
            rescue BadMessageError => e
              log_debug { e.message }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_BAD_MESSAGE,
                :"error message" => "Bad message",
                :"language tag"  => "",
              }
            rescue FileLutimeUnsupportedError => e
              log_debug { e.message }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => e.message,
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
            rescue Errno::EACCES, Errno::EPERM => e
              log_debug { e.message }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
                :"error message" => "Permission denied",
                :"language tag"  => "",
              }
            rescue NotImplementedError => e
              log_debug { e.message }
              {
                :"type"          => Packets::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packets::SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => e.message,
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

          class BadMessageError < StandardError
          end

          class FileLutimeUnsupportedError < StandardError
          end

          private_constant :BadMessageError, :FileLutimeUnsupportedError
        end
      end
    end
  end
end
