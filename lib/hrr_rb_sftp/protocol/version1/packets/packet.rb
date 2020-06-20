module HrrRbSftp
  class Protocol
    class Version1
      class Packets

        #
        # This class implements base packet operations and is to be inherited by each packet class.
        #
        class Packet < Common::Packets::Packet

          #
          # Returns a new instance of a class that includes this module.
          #
          # @param context [Hash] Contextual variables.
          #   - :version (Integer) - Negotiated protocol version.
          #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
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
          #   - :version (Integer) - Negotiated protocol version.
          #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
          #
          def context
            @context
          end

          #
          # Returns Negotiated protocol version.
          #
          # @return [Integer] Negotiated protocol version.
          #
          def version
            @context[:version]
          end

          #
          # Returns opened handles.
          #
          # @return [Hash{String=>File, Dir}] Opened handles.
          #
          def handles
            @context[:handles]
          end
        end
      end
    end
  end
end
