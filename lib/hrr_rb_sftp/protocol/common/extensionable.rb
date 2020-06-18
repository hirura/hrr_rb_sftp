module HrrRbSftp
  class Protocol
    module Common

      #
      # This module implements common extension operations and is to be included in each extension class.
      #
      module Extensionable
        include Loggable

        #
        # Returns a new instance of a class that includes this module.
        #
        # @param handles [Hash{String=>File}, Hash{String=>Dir}] A list of opened handles.
        # @param logger [Logger] Logger.
        #
        def initialize handles, logger: nil
          self.logger = logger

          @handles = handles
        end

        #
        # Returns opened handles.
        #
        # @return [Hash{String=>File, Dir}] Opened handles.
        #
        def handles
          @handles
        end
      end
    end
  end
end
