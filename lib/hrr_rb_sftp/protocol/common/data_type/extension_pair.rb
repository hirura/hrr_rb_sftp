module HrrRbSftp
  class Protocol
    module Common
      module DataType
        module ExtensionPair
          def self.encode arg
            unless arg.kind_of? ::Hash
              raise ArgumentError, "must be a kind of Hash, but got #{arg.inspect}"
            end
            DataType::String.encode(arg[:"extension-name"]) + DataType::String.encode(arg[:"extension-data"])
          end

          def self.decode io
            {
              :"extension-name" => DataType::String.decode(io),
              :"extension-data" => DataType::String.decode(io),
            }
          end
        end
      end
    end
  end
end
