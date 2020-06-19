module HrrRbSftp
  class Protocol
    class Version3
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
          #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
          #   - :extensions (Extensions) - An instance of Extensions.
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
