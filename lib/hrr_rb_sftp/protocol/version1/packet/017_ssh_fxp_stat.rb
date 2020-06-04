module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_STAT
          include Common::Packetable

          TYPE = 17

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"path"      ],
          ]

          def respond_to request
            begin
              stat = File.stat(request[:"path"])
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
            rescue Errno::ENOENT
              {
                :"type"       => SSH_FXP_STATUS::TYPE,
                :"request-id" => request[:"request-id"],
                :"code"       => SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
              }
            rescue Errno::EACCES
              {
                :"type"       => SSH_FXP_STATUS::TYPE,
                :"request-id" => request[:"request-id"],
                :"code"       => SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
              }
            rescue
              {
                :"type"       => SSH_FXP_STATUS::TYPE,
                :"request-id" => request[:"request-id"],
                :"code"       => SSH_FXP_STATUS::SSH_FX_FAILURE,
              }
            end
          end
        end
      end
    end
  end
end
