module HrrRbSftp
  class Protocol
    @subclasses = Array.new

    class << self
      def inherited klass
        @subclasses.push klass if @subclasses
      end

      def versions
        __subclasses__(__method__).map{ |klass| [klass::PROTOCOL_VERSION, klass] }.inject(Hash.new){|h,(k,v)| h.update({k => v})}
      end

      private

      def __subclasses__ method_name
        send(:method_missing, method_name) unless @subclasses
        @subclasses
      end
    end
  end
end

require "hrr_rb_sftp/protocol/common"
require "hrr_rb_sftp/protocol/version1"
require "hrr_rb_sftp/protocol/version2"
