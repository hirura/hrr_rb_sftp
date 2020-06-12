module HrrRbSftp
  class Protocol
    class Version1
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_OPEN packet type, format, and responder.
        #
        class SSH_FXP_OPEN
          include Common::Packetable

          #
          # Represents SSH_FXP_OPEN packet type.
          #
          TYPE = 3

          #
          # Represents SSH_FXP_OPEN packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::String, :"filename"  ],
            [DataType::Uint32, :"pflags"    ],
            [DataType::Attrs,  :"attrs"     ],
          ]

          #
          # Represents SSH_FXF_READ flag.
          #
          SSH_FXF_READ   = 0x00000001

          #
          # Represents SSH_FXF_WRITE flag.
          #
          SSH_FXF_WRITE  = 0x00000002

          #
          # Represents SSH_FXF_APPEND flag.
          #
          SSH_FXF_APPEND = 0x00000004

          #
          # Represents SSH_FXF_CREAT flag.
          #
          SSH_FXF_CREAT  = 0x00000008

          #
          # Represents SSH_FXF_TRUNC flag.
          #
          SSH_FXF_TRUNC  = 0x00000010

          #
          # Represents SSH_FXF_EXCL flag.
          #
          SSH_FXF_EXCL   = 0x00000020

          #
          # Responds to SSH_FXP_OPEN request.
          #
          # @param request [Hash{Symbol=>Object}] SSH_FXP_OPEN request represented in Hash.
          #                                       Only permissions attribute is taken care of.
          #                                       When attrs field contains attributes other than permissions are ignored
          #                                       and they are expected to be taken care of by subsequent SSH_FXP_SETSTAT and/or SSH_FXP_FSETSTAT requests.
          # @return [Hash{Symbol=>Object}] Response represented in Hash. In case of success, its type is SSH_FXP_HANDLE. In other cases, its type is SSH_FXP_STATUS.
          #
          def respond_to request
            begin
              flags = convert_pflags_to_flags request[:"pflags"]
              args = [request[:"filename"], flags]
              if (flags & ::File::CREAT == ::File::CREAT) && request[:"attrs"].has_key?(:"permissions")
                args.push request[:"attrs"][:"permissions"]
              end
              file = ::File.open(*args)
              handle = file.object_id.to_s(16)
              @handles[handle] = file
              {
                :"type"       => SSH_FXP_HANDLE::TYPE,
                :"request-id" => request[:"request-id"],
                :"handle"     => handle,
              }
            rescue Error => e
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_FAILURE,
                :"error message" => e.message,
                :"language tag"  => "",
              }
            rescue Errno::ENOENT
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE,
                :"error message" => "No such file or directory",
                :"language tag"  => "",
              }
            rescue Errno::EACCES
              {
                :"type"          => SSH_FXP_STATUS::TYPE,
                :"request-id"    => request[:"request-id"],
                :"code"          => SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED,
                :"error message" => "Permission denied",
                :"language tag"  => "",
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

          class Error < StandardError
          end

          private_constant :Error

          private

          def convert_pflags_to_flags pflags
            flags = 0
            if ((pflags & SSH_FXF_READ) == SSH_FXF_READ) && ((pflags & SSH_FXF_WRITE) == SSH_FXF_WRITE)
              flags |= ::File::RDWR
            elsif (pflags & SSH_FXF_READ) == SSH_FXF_READ
              flags |= ::File::RDONLY
            elsif (pflags & SSH_FXF_WRITE) == SSH_FXF_WRITE
              flags |= ::File::WRONLY
            else
              raise Error, "At least SSH_FXF_READ or SSH_FXF_READ must be specified"
            end
            if (pflags & SSH_FXF_APPEND) == SSH_FXF_APPEND
              flags |= ::File::APPEND
            end
            if (pflags & SSH_FXF_CREAT) == SSH_FXF_CREAT
              flags |= ::File::CREAT
              flags |= ::File::TRUNC if (pflags & SSH_FXF_TRUNC) == SSH_FXF_TRUNC
              flags |= ::File::EXCL  if (pflags & SSH_FXF_EXCL ) == SSH_FXF_EXCL
            elsif (pflags & SSH_FXF_TRUNC) == SSH_FXF_TRUNC
              raise Error, "SSH_FXF_CREAT MUST also be specified when SSH_FXF_TRUNC is specified"
            elsif (pflags & SSH_FXF_EXCL) == SSH_FXF_EXCL
              raise Error, "SSH_FXF_CREAT MUST also be specified when SSH_FXF_EXCL is specified"
            end
            flags |= ::File::BINARY
            flags
          end
        end
      end
    end
  end
end
