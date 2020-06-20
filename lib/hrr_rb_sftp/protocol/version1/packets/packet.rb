module HrrRbSftp
  class Protocol
    class Version1
      module Packets

        #
        # This class implements base packet operations and is to be inherited by each packet class.
        #
        class Packet < Common::Packets::Packet

          #
          # Returns a new instance of a class that includes this module.
          #
          # @param context [Hash] Contextual variables.
          #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
          #   - :extensions (Extensions) - An instance of Extensions.
          # @param logger [Logger] Logger.
          #
          def initialize context, logger: nil
            super logger: logger

            @context = context
          end

          #
          # Returns contextual variables.
          #
          # @return [Hash] Contextual variables.
          #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
          #   - :extensions (Extensions) - An instance of Extensions.
          #
          def context
            @context
          end

          #
          # Returns opened handles.
          #
          # @return [Hash{String=>File, Dir}] Opened handles.
          #
          def handles
            @context[:handles]
          end

          #
          # Returns An instance of Extensions.
          #
          # @return [Extensions] An instance of Extensions.
          #
          def extensions
              @context[:extensions]
          end
        end
      end
    end
  end
end
