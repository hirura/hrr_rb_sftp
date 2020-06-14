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
        def self.conditional_format
          @conditional_format ||= (
            extensions = constants.map{|c| const_get(c)}.select{|c| c.const_defined?(:EXTENDED_NAME)}
            extended_request_format = extensions.inject(Hash.new){|h, c| h.merge(c.const_defined?(:EXTENDED_FORMAT) ? c::EXTENDED_FORMAT : {})}
            {
              :"extended-request" => extended_request_format,
            }
          )
        end
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version3/extension/hardlink_at_openssh_com"
require "hrr_rb_sftp/protocol/version3/extension/fsync_at_openssh_com"
require "hrr_rb_sftp/protocol/version3/extension/posix_rename_at_openssh_com"
