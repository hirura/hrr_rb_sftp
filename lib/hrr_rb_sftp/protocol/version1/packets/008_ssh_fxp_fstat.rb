module HrrRbSftp
  class Protocol
    class Version1
      module Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_FSTAT packet type, format, and responder.
        #
        class SSH_FXP_FSTAT < Packet

          #
          # Represents SSH_FXP_FSTAT packet type.
          #
          TYPE = 8

          #
          # Represents SSH_FXP_FSTAT packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::String, :"handle"    ],
          ]

          #
          # Responds to SSH_FXP_FSTAT request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_FSTAT request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. In case of success, its type is SSH_FXP_ATTRS. In other cases, its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              raise "Specified handle does not exist" unless handles.has_key?(request[:"handle"])
              log_debug { "file = handles[#{request[:"handle"].inspect}]" }
              file = handles[request[:"handle"]]
              log_debug { "file.stat" }
              stat = file.stat
              attrs = Hash.new
              attrs[:"size"]        = stat.size       if stat.size
              attrs[:"uid"]         = stat.uid        if stat.uid
              attrs[:"gid"]         = stat.gid        if stat.gid
              attrs[:"permissions"] = stat.mode       if stat.mode
              attrs[:"atime"]       = stat.atime.to_i if stat.atime
              attrs[:"mtime"]       = stat.mtime.to_i if stat.mtime
              {
                :"type"       => SSH_FXP_ATTRS::TYPE,
                :"request-id" => request[:"request-id"],
                :"attrs"      => attrs,
              }
            rescue => e
              log_error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_FAILURE,
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
