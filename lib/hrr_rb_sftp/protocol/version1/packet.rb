module HrrRbSftp
  class Protocol
    class Version1
      class Packet
        @subclasses = Array.new

        class << self
          def inherited klass
            @subclasses.push klass if @subclasses
          end

          def list
            __subclasses__(__method__)
          end

          def __subclasses__ method_name
            send(:method_missing, method_name) unless @subclasses
            @subclasses
          end

          private :__subclasses__
        end

        include Common::Packetable
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version1/packet/016_ssh_fxp_realpath"
