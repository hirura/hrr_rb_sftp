module HrrRbSftp
  class Protocol
    module Common
      module DataType
        module ExtensionPairs
          def self.encode arg
            unless arg.kind_of? ::Array
              raise ArgumentError, "must be a kind of Array, but got #{arg.inspect}"
            end
            arg.map{|arg| ExtensionPair.encode(arg)}.join
          end

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
