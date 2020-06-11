module HrrRbSftp
  class Protocol
    module Common
      module DataType

        #
        # This module provides methods to convert ::Integer value and 8-bit unsigned binary string each other.
        #
        module Byte

          #
          # Convert ::Integer value into 8-bit unsigned binary string.
          #
          # @param arg [::Integer] ::Integer value to be converted.
          # @raise [::ArgumentError] When arg is not between 0x00 and 0xff.
          # @return [::String] Converted 8-bit unsigned binary string.
          #
          def self.encode arg
            case arg
            when 0x00..0xff
              [arg].pack("C")
            else
              raise ArgumentError, "must be in #{0x00}..#{0xff}, but got #{arg.inspect}"
            end
          end

          #
          # Convert 8-bit unsigned binary into ::Integer value.
          #
          # @param io [::IO] ::IO instance that has buffer to be read.
          # @return [::Integer] Converted ::Integer value.
          #
          def self.decode io
            io.read(1).unpack("C")[0]
          end
        end
      end
    end
  end
end
