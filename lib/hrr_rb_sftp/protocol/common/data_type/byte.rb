module HrrRbSftp
  class Protocol
    module Common
      module DataType
        module Byte
          def self.encode arg
            case arg
            when 0x00..0xff
              [arg].pack("C")
            else
              raise ArgumentError, "must be in #{0x00}..#{0xff}, but got #{arg.inspect}"
            end
          end

          def self.decode io
            io.read(1).unpack("C")[0]
          end
        end
      end
    end
  end
end
