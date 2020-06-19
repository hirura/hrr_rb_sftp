module HrrRbSftp
  class Protocol
    module Common
      module DataTypes

        #
        # This module provides methods to convert extension-name and extension-data pair represented in ::Hash and binary string each other.
        #
        module ExtensionPair

          #
          # Convert extension-name and extension-data pair represented in ::Hash into binary string.
          #
          # @param arg [::Hash{::Symbol=>::String}] Extension-name and extension-data pair represented in ::Hash to be converted.
          # @raise [::ArgumentError] When arg is not ::Hash value.
          # @return [::String] Converted binary string.
          #
          def self.encode arg
            unless arg.kind_of? ::Hash
              raise ArgumentError, "must be a kind of Hash, but got #{arg.inspect}"
            end
            DataTypes::String.encode(arg[:"extension-name"]) + DataTypes::String.encode(arg[:"extension-data"])
          end

          #
          # Convert binary string into extension-name and extension-data pair represented in ::Hash.
          #
          # @param io [::IO] ::IO instance that has buffer to be read.
          # @return [::Hash{::Symbol=>::String}] Converted extension-name and extension-data pair represented in ::Hash.
          #
          def self.decode io
            {
              :"extension-name" => DataTypes::String.decode(io),
              :"extension-data" => DataTypes::String.decode(io),
            }
          end
        end
      end
    end
  end
end
