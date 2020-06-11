module HrrRbSftp
  class Protocol
    module Common
      module DataType

        #
        # This module provides methods to convert ::Integer value and 32-bit unsigned binary string each other.
        #
        module Uint32

          #
          # Convert ::Integer value into 32-bit unsigned binary string.
          #
          # @param arg [::Integer] ::Integer value to be converted.
          # @raise [::ArgumentError] When arg is not between 0x0000_0000 and 0xffff_ffff.
          # @return [::String] Converted 32-bit unsigned binary string.
          #
          def self.encode arg
            case arg
            when 0x0000_0000..0xffff_ffff
              [arg].pack("N")
            else
              raise ArgumentError, "must be in #{0x0000_0000}..#{0xffff_ffff}, but got #{arg.inspect}"
            end
          end

          #
          # Convert 32-bit unsigned binary into ::Integer value.
          #
          # @param io [::IO] ::IO instance that has buffer to be read.
          # @return [::Integer] Converted ::Integer value.
          #
          def self.decode io
            io.read(4).unpack("N")[0]
          end
        end
      end
    end
  end
end
