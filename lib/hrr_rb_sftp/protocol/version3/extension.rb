module HrrRbSftp
  class Protocol
    class Version3

      #
      # This class implements SFTP protocol version 3 extension formats and responders.
      #
      class Extension

        #
        # @return [Hash{Symbol=>Hash{String=>Array<Array(Object, Symbol)>}}] Conditional format used in extended-request packet.
        #
        def self.conditional_request_format
          Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = request_formats.select{|f| f.keys.include? k}.map{|f| f[k]}.inject(Hash.new, &:merge)[k2]}}
        end

        #
        # @return [Hash{Symbol=>Hash{String=>Array<Array(Object, Symbol)>}}] Conditional format used in extended-reply packet.
        #
        def self.conditional_reply_format
          Hash.new{|h,k| h[k] = Hash.new{|h2,k2| h2[k2] = reply_formats.select{|f| f.keys.include? k}.map{|f| f[k]}.inject(Hash.new, &:merge)[k2]}}
        end

        private

        def self.extensions
          constants.map{|c| const_get(c)}.select{|c| c.const_defined?(:EXTENSION_NAME)}
        end

        def self.request_formats
          extensions.map{|e| e.const_defined?(:REQUEST_FORMAT) ? e::REQUEST_FORMAT : {}}
        end

        def self.reply_formats
          extensions.map{|e| e.const_defined?(:REPLY_FORMAT) ? e::REPLY_FORMAT : {}}
        end
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version3/extension/hardlink_at_openssh_com"
require "hrr_rb_sftp/protocol/version3/extension/fsync_at_openssh_com"
require "hrr_rb_sftp/protocol/version3/extension/posix_rename_at_openssh_com"
