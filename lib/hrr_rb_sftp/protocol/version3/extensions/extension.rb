module HrrRbSftp
  class Protocol
    module Version3
      class Extensions

        #
        # This class implements base extension operations and is to be inherited by each extension class.
        #
        class Extension
          include Loggable

          #
          # Returns a new instance of a class that includes this module.
          #
          # @param context [Hash] Contextual variables.
          #   - :version (Integer) - Negotiated protocol version.
          #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
          # @param logger [Logger] Logger.
          #
          def initialize context, logger: nil
            self.logger = logger

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
