module HrrRbSftp
  class Protocol
    module Common
      module DataType
        module Uint32
          def self.encode arg
            case arg
            when 0x0000_0000..0xffff_ffff
              [arg].pack("N")
            else
              raise ArgumentError, "must be in #{0x0000_0000}..#{0xffff_ffff}, but got #{arg.inspect}"
            end
          end

          def self.decode io
            io.read(4).unpack("N")[0]
          end
        end
      end
    end
  end
end
