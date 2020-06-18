module HrrRbSftp
  class Protocol
    class Version3
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_EXTENDED packet type, format, and responder.
        #
        class SSH_FXP_EXTENDED
          include Common::Packetable

          #
          # Represents SSH_FXP_EXTENDED packet type.
          #
          TYPE = 200

          #
          # Represents SSH_FXP_EXTENDED packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"            ],
            [DataType::Uint32, :"request-id"      ],
            [DataType::String, :"extended-request"],
          ]

          #
          # Represents SSH_FXP_EXTENDED packet conditional format.
          #
          # @example
          #   {
          #     :"extended-request" => {
          #       "hardlink@openssh.com" => [
          #         [DataType::String, :"oldpath"],
          #         [DataType::String, :"newpath"],
          #       ],
          #     },
          #   }
          #
          CONDITIONAL_FORMAT = Extension.conditional_request_format

          #
          # Responds to SSH_FXP_EXTENDED request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_EXTENDED request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. Its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              @extensions ||= (
                extension_classes = Extension.constants.map{|c| Extension.const_get(c)}.select{|c| c.const_defined?(:EXTENSION_NAME)}
                extensions = Hash.new
                extension_classes.each do |c|
                  if extended_requests = c::REQUEST_FORMAT[:"extended-request"]
                    instance = c.new(handles, logger: logger)
                    extended_requests.each_key do |k|
                      extensions[k] = instance
                    end
                  end
                end
                extensions
              )
              extended_request = request[:"extended-request"]
              if @extensions.has_key?(extended_request)
                @extensions[extended_request].respond_to request
              else
                {
                  :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_OP_UNSUPPORTED,
                  :"error message" => "Unsupported extended-request: #{extended_request}",
                  :"language tag"  => "",
                }
              end
            rescue => e
              log_error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
              {
                :"type"          => Packet::SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => Packet::SSH_FXP_STATUS::SSH_FX_FAILURE,
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
