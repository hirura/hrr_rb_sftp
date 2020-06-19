module HrrRbSftp
  class Protocol
    module Common
      module DataTypes

        #
        # This module provides methods to convert ::Integer value and 64-bit unsigned binary string each other.
        #
        module Uint64

          #
          # Convert ::Integer value into 64-bit unsigned binary string.
          #
          # @param arg [::Integer] ::Integer value to be converted.
          # @raise [::ArgumentError] When arg is not between 0x0000_0000_0000_0000 and 0xffff_ffff_ffff_ffff.
          # @return [::String] Converted 64-bit unsigned binary string.
          #
          def self.encode arg
            case arg
            when 0x0000_0000_0000_0000..0xffff_ffff_ffff_ffff
              [arg >> 32].pack("N") + [arg & 0x0000_0000_ffff_ffff].pack("N")
            else
              raise ArgumentError, "must be in #{0x0000_0000_0000_0000}..#{0xffff_ffff_ffff_ffff}, but got #{arg.inspect}"
            end
          end

          #
          # Convert 64-bit unsigned binary into ::Integer value.
          #
          # @param io [::IO] ::IO instance that has buffer to be read.
          # @return [::Integer] Converted ::Integer value.
          #
          def self.decode io
            (io.read(4).unpack("N")[0] << 32) + (io.read(4).unpack("N")[0])
          end
        end
      end
    end
  end
end
