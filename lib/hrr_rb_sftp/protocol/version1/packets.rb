module HrrRbSftp
  class Protocol
    module Version1

      #
      # This class implements SFTP protocol version 1 packet types, formats, and responders.
      #
      class Packets
        include Loggable

        #
        # @param context [Hash] Contextual variables.
        #   - :version (Integer) - Negotiated protocol version.
        #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
        # @param logger [Logger] Logger.
        #
        def initialize context, logger: nil
          self.logger = logger

          @packets = packet_classes.map{|c| {c::TYPE => c.new(context, logger: logger)}}.inject({}, :merge)
        end

        #
        # Responds to a request.
        #
        # @param request_payload [String] Request payload.
        # @return [String] Response payload that is encoded packet generated by each SFTP protocol version and each request responder.
        # @raise [RuntimeError] When the SFTP protocol version does not support or the library does not implement the request type.
        #
        def respond_to request_payload
          request_type = request_payload[0].unpack("C")[0]
          response_packet = if @packets.has_key?(request_type)
                              request_packet = @packets[request_type].decode request_payload
                              @packets[request_type].respond_to request_packet
                            else
                              raise RuntimeError, "Unsupported type: #{request_type}"
                            end
          response_type = response_packet[:"type"]
          @packets[response_type].encode response_packet
        end

        private

        def packet_classes
          self.class.constants.select{|c| c.to_s.start_with?("SSH_FXP_")}.map{|c| self.class.const_get(c)}
        end
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version1/packets/packet"
require "hrr_rb_sftp/protocol/version1/packets/003_ssh_fxp_open"
require "hrr_rb_sftp/protocol/version1/packets/004_ssh_fxp_close"
require "hrr_rb_sftp/protocol/version1/packets/005_ssh_fxp_read"
require "hrr_rb_sftp/protocol/version1/packets/006_ssh_fxp_write"
require "hrr_rb_sftp/protocol/version1/packets/007_ssh_fxp_lstat"
require "hrr_rb_sftp/protocol/version1/packets/008_ssh_fxp_fstat"
require "hrr_rb_sftp/protocol/version1/packets/009_ssh_fxp_setstat"
require "hrr_rb_sftp/protocol/version1/packets/010_ssh_fxp_fsetstat"
require "hrr_rb_sftp/protocol/version1/packets/011_ssh_fxp_opendir"
require "hrr_rb_sftp/protocol/version1/packets/012_ssh_fxp_readdir"
require "hrr_rb_sftp/protocol/version1/packets/013_ssh_fxp_remove"
require "hrr_rb_sftp/protocol/version1/packets/014_ssh_fxp_mkdir"
require "hrr_rb_sftp/protocol/version1/packets/015_ssh_fxp_rmdir"
require "hrr_rb_sftp/protocol/version1/packets/016_ssh_fxp_realpath"
require "hrr_rb_sftp/protocol/version1/packets/017_ssh_fxp_stat"
require "hrr_rb_sftp/protocol/version1/packets/101_ssh_fxp_status"
require "hrr_rb_sftp/protocol/version1/packets/102_ssh_fxp_handle"
require "hrr_rb_sftp/protocol/version1/packets/103_ssh_fxp_data"
require "hrr_rb_sftp/protocol/version1/packets/104_ssh_fxp_name"
require "hrr_rb_sftp/protocol/version1/packets/105_ssh_fxp_attrs"
