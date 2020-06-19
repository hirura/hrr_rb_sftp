module HrrRbSftp
  class Protocol
    class Version3

      #
      # This class implements SFTP protocol version 3 extension formats and responders.
      #
      class Extensions
        include Loggable

        #
        # @return [Array<Class>] A list of classes that has EXTENSION_NAME constant.
        #
        def self.extension_classes
          constants.map{|c| const_get(c)}.select{|c| c.respond_to?(:const_defined?) && c.const_defined?(:EXTENSION_NAME)}
        end

        #
        # @param context [Hash] Contextual variables.
        #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
        #   - :extensions (Extensions) - An instance of Extensions.
        # @param logger [Logger] Logger.
        #
        def initialize context, logger: nil
          self.logger = logger

          @conditional_request_format = conditional_request_format
          @conditional_reply_format   = conditional_reply_format
          @extensions = extension_classes.map{ |c|
                          extension = c.new(context, logger: logger)
                          (c::REQUEST_FORMAT[:"extended-request"] || {}).keys.map{|key| {key => extension} }.inject({}, &:merge)
                        }.inject({}, &:merge)
        end

        #
        # @return [Boolean] true if request's extended-request is supported. false if not.
        #
        def respond_to? request
          extended_request = request[:"extended-request"]
          @extensions.has_key?(extended_request)
        end

        #
        # @return [Hash{Symbol=>Object] Response represented in Hash.
        #
        def respond_to request
          extended_request = request[:"extended-request"]
          @extensions[extended_request].respond_to request
        end

        #
        # @return [Hash{Symbol=>Hash{String=>Array<Array(Object, Symbol)>}}] Conditional format used in extended-request packet.
        #
        def conditional_request_format
          @conditional_request_format ||= Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = request_formats.select{|f| f.has_key? k}.map{|f| f[k]}.inject({}, &:merge)[k2]}}
        end

        #
        # @return [Hash{Symbol=>Hash{String=>Array<Array(Object, Symbol)>}}] Conditional format used in extended-reply packet.
        #
        def conditional_reply_format
          @conditional_reply_format ||= Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = reply_formats.select{|f| f.has_key? k}.map{|f| f[k]}.inject({}, &:merge)[k2]}}
        end

        private

        def extension_classes
          self.class.constants.map{|c| self.class.const_get(c)}.select{|c| c.respond_to?(:const_defined?) && c.const_defined?(:EXTENSION_NAME)}
        end

        def request_formats
          extension_classes.map{|c| c.const_defined?(:REQUEST_FORMAT) ? c::REQUEST_FORMAT : {}}
        end

        def reply_formats
          extension_classes.map{|c| c.const_defined?(:REPLY_FORMAT) ? c::REPLY_FORMAT : {}}
        end
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version3/extensions/hardlink_at_openssh_com"
require "hrr_rb_sftp/protocol/version3/extensions/fsync_at_openssh_com"
require "hrr_rb_sftp/protocol/version3/extensions/posix_rename_at_openssh_com"
require "hrr_rb_sftp/protocol/version3/extensions/lsetstat_at_openssh_com"
