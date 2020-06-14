module HrrRbSftp
  class Protocol
    class Version3
      class Extension

        #
        # This class implements hardlink@openssh.com version 1 extension format and responder.
        #
        class HardlinkAtOpensshCom
          include Loggable

          #
          # Represents hardlink@openssh.com version 1 extension name.
          #
          EXTENDED_NAME = "hardlink@openssh.com"

          #
          # Represents hardlink@openssh.com version 1 extension data.
          #
          EXTENDED_DATA = "1"

          #
          # Represents SSH_FXP_EXTENDED packet additional format for hardlink@openssh.com version 1 extension.
          #
          EXTENDED_FORMAT = {
            "hardlink@openssh.com" => [
                                        [DataType::String, :"oldpath"],
                                        [DataType::String, :"newpath"],
                                      ],
          }

          #
          # Returns a new instance of the class.
          #
          # @param handles [Hash{String=>File}, Hash{String=>Dir}] A list of opened handles.
          # @param logger [Logger] Logger.
          #
          def initialize handles, logger: nil
            self.logger = logger

            @handles = handles
          end

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
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
                :"language tag"  => "",
              }
            rescue Errno::ENOENT => e
              log_debug { e.message }
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
                :"error message" => "No such file or directory",
                :"language tag"  => "",
              }
            rescue Errno::EACCES => e
              log_debug { e.message }
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
                :"error message" => "Permission denied",
                :"language tag"  => "",
              }
            rescue Errno::EEXIST => e
              log_debug { e.message }
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_FAILURE,
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

