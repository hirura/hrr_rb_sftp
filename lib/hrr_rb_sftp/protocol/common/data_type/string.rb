module HrrRbSftp
  class Protocol
    module Common
      module DataType

        #
        # This module provides methods to convert ::String value and binary string with its length each other.
        #
        module String

          #
          # Convert ::String value into binary string with its length.
          #
          # @param arg [::String] ::String value to be converted.
          # @raise [::ArgumentError] When arg is not ::String value or length of arg is longer than 0xffff_ffff.
          # @return [::String] Converted binary string with its length.
          #
          def self.encode arg
            unless arg.kind_of? ::String
              raise ArgumentError, "must be a kind of String, but got #{arg.inspect}"
            end
            if arg.bytesize > 0xffff_ffff
              raise ArgumentError, "must be shorter than or equal to #{0xffff_ffff}, but got length #{arg.bytesize}"
            end
            [arg.bytesize, arg].pack("Na*")
          end

          #
          # Convert binary string with its length into ::String value.
          #
          # @param io [::IO] ::IO instance that has buffer to be read.
          # @return [::String] Converted UTF-8 ::String value.
          #
          def self.decode io
            length = io.read(4).unpack("N")[0]
            io.read(length).unpack("a*")[0].force_encoding(Encoding::UTF_8)
          end
        end
      end
    end
  end
end
