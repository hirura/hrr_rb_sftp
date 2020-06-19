module HrrRbSftp
  class Protocol
    module Common
      module DataTypes

        #
        # This module provides methods to convert list of extension-name and extension-data pair represented in ::Array and binary string each other.
        #
        module ExtensionPairs

          #
          # Convert list of extension-name and extension-data pair represented in ::Array into binary string.
          #
          # @param arg [::Array<::Hash{::Symbol=>::String}>] List of extension-name and extension-data pair represented in ::Array to be converted.
          # @raise [::ArgumentError] When arg is not ::Array value.
          # @return [::String] Converted binary string.
          #
          def self.encode arg
            unless arg.kind_of? ::Array
              raise ArgumentError, "must be a kind of Array, but got #{arg.inspect}"
            end
            arg.map{|arg| ExtensionPair.encode(arg)}.join
          end

          #
          # Convert binary string into list of extension-name and extension-data pair represented in ::Array.
          #
          # @param io [::IO] ::IO instance that has buffer to be read.
          # @return [::Array<::Hash{::Symbol=>::String}>] Converted list of extension-name and extension-data pair represented in ::Array.
          #
          def self.decode io
            extension_pairs = Array.new
            until io.eof?
              extension_pairs.push ExtensionPair.decode(io)
            end
            extension_pairs
          end
        end
      end
    end
  end
end
