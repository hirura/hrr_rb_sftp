module HrrRbSftp
  class Protocol
    class Version1
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_READDIR packet type, format, and responder.
        #
        class SSH_FXP_READDIR
          include Common::Packetable

          #
          # Represents SSH_FXP_READDIR packet type.
          #
          TYPE = 12

          #
          # Represents SSH_FXP_READDIR packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"handle"    ],
          ]

          #
          # Responds to SSH_FXP_READDIR request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_READDIR request represented in Hash.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. In case of success, its type is SSH_FXP_NAME. In other cases, its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              raise "Specified handle does not exist" unless handles.has_key?(request[:"handle"])
              log_debug { "dir = handles[#{request[:"handle"].inspect}]" }
              dir = handles[request[:"handle"]]
              raise "Specified handle is not directory" unless dir.instance_of?(::Dir)
              entries = ::Array.new
              while entry = dir.read
                log_debug { "#{entry.inspect} = dir.read" }
                log_debug { "entries.push #{entry.inspect}" }
                entries.push entry
              end
              unless entries.empty?
                log_debug { "entries is not empty" }
                log_debug { "count = #{entries.size.inspect}" }
                count = entries.size
                response = {
                  :"type"       => SSH_FXP_NAME::TYPE,
                  :"request-id" => request[:"request-id"],
                  :"count"      => count,
                }
                entries.each.with_index do |entry, idx|
                  response[:"filename[#{idx}]"] = entry
                  response[:"longname[#{idx}]"] = longname(dir, entry)
                  response[:"attrs[#{idx}]"]    = attrs(dir, entry)
                end
                response
              else
                log_debug { "entries is empty" }
                {
                  :"type"          => SSH_FXP_STATUS::TYPE,
                  :"request-id"    => request[:"request-id"],
                  :"code"          => SSH_FXP_STATUS::SSH_FX_EOF,
                  :"error message" => "End of file",
                  :"language tag"  => "",
                }
              end
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

          private

          def longname_permissions stat
            s = ::String.new
            s += case stat.mode & 0170000
                 when 0140000 then "s"
                 when 0120000 then "l"
                 when 0100000 then "-"
                 when 0060000 then "b"
                 when 0040000 then "d"
                 when 0020000 then "c"
                 when 0010000 then "p"
                 else "?"
                 end
            s += (stat.mode & 0400) == 0400 ? "r" : "-"
            s += (stat.mode & 0200) == 0200 ? "w" : "-"
            s += (stat.mode & 0100) == 0100 ? "x" : "-"
            s += (stat.mode & 0040) == 0040 ? "r" : "-"
            s += (stat.mode & 0020) == 0020 ? "w" : "-"
            s += (stat.mode & 0010) == 0010 ? "x" : "-"
            s += (stat.mode & 0004) == 0004 ? "r" : "-"
            s += (stat.mode & 0002) == 0002 ? "w" : "-"
            s += (stat.mode & 0001) == 0001 ? "x" : "-"
            s
          end

          def longname_nlink stat
            stat.nlink.to_s.rjust(3, " ")
          end

          def longname_user stat
            (::Etc.getpwuid(stat.uid).name rescue stat.uid).to_s.ljust(8, " ")
          end

          def longname_group stat
            (::Etc.getgrgid(stat.gid).name rescue stat.gid).to_s.ljust(8, " ")
          end

          def longname_size stat
            stat.size.to_s.rjust(8, " ")
          end

          def longname_mtime stat
            if stat.mtime.year == ::Time.now.year
              stat.mtime.strftime "%b %e %H:%M"
            else
              stat.mtime.strftime "%b %e  %Y"
            end
          end

          def longname dir, entry
            stat = ::File.lstat(::File.join(dir.path, entry))
            [
              longname_permissions(stat),
              longname_nlink(stat),
              longname_user(stat),
              longname_group(stat),
              longname_size(stat),
              longname_mtime(stat),
              entry,
            ].join(" ")
          end

          def attrs dir, entry
            stat = ::File.lstat(::File.join(dir.path, entry))
            attrs = ::Hash.new
            attrs[:"size"]        = stat.size       if stat.size
            attrs[:"uid"]         = stat.uid        if stat.uid
            attrs[:"gid"]         = stat.gid        if stat.gid
            attrs[:"permissions"] = stat.mode       if stat.mode
            attrs[:"atime"]       = stat.atime.to_i if stat.atime
            attrs[:"mtime"]       = stat.mtime.to_i if stat.mtime
            attrs
          end
        end
      end
    end
  end
end
