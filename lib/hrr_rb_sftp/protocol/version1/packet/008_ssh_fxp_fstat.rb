module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_FSTAT
          include Common::Packetable

          TYPE = 8

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
          ]

          def respond_to request
            begin
              raise "Specified handle does not exist" unless @handles.has_key?(request[:"handle"])
              file = @handles[request[:"handle"]]
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
