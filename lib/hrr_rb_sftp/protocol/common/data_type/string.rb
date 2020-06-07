module HrrRbSftp
  class Protocol
    module Common
      module DataType
        module String
          def self.encode arg
            unless arg.kind_of? ::String
              raise ArgumentError, "must be a kind of String, but got #{arg.inspect}"
            end
            if arg.bytesize > 0xffff_ffff
              raise ArgumentError, "must be shorter than or equal to #{0xffff_ffff}, but got length #{arg.bytesize}"
            end
            [arg.bytesize, arg].pack("Na*")
          end

          def self.decode io
            length = io.read(4).unpack("N")[0]
            io.read(length).unpack("a*")[0].force_encoding(Encoding::UTF_8)
          end
        end
      end
    end
  end
end
