module HrrRbSftp
  class Protocol
    class Version3
      module Extension

        #
        # This module implements hardlink@openssh.com version 1 extension format and responder.
        #
        module HardlinkAtOpensshCom

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
          HARDLINK_AT_OPENSSH_COM_FORMAT = [
            [DataType::String, :"oldpath"],
            [DataType::String, :"newpath"],
          ]

          #
          # Represents SSH_FXP_EXTENDED packet additional responder for hardlink@openssh.com version 1 extension.
          #
          HARDLINK_AT_OPENSSH_COM_RESPONDER = lambda{ |request|
            begin
              File.link request[:"oldpath"], request[:"newpath"]
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_OK,
                :"error message" => "Success",
                :"language tag"  => "",
              }
            rescue Errno::ENOENT
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
                :"error message" => "No such file or directory",
                :"language tag"  => "",
              }
            rescue Errno::EACCES
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
                :"error message" => "Permission denied",
                :"language tag"  => "",
              }
            rescue Errno::EEXIST
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => "File exists",
                :"language tag"  => "",
              }
            end
          }

          Packet::SSH_FXP_EXTENDED::CONDITIONAL_FORMAT[:"extended-request"]["hardlink@openssh.com"] = HARDLINK_AT_OPENSSH_COM_FORMAT
          Packet::SSH_FXP_EXTENDED::CONDITIONAL_RESPONDER[:"extended-request"]["hardlink@openssh.com"] = HARDLINK_AT_OPENSSH_COM_RESPONDER
        end
      end
    end
  end
end

