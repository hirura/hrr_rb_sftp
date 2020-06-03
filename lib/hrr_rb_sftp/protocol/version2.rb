module HrrRbSftp
  class Protocol
    class Version2 < Protocol
      include Loggable

      PROTOCOL_VERSION = 2

      def initialize logger: nil
        self.logger = logger

        @packets = Packet.list.map{|pkt| [pkt::TYPE, pkt.new(logger: logger)]}.inject(Hash.new){|h,(k,v)| h.update({k => v})}
      end

      def respond_to request_payload
        request_type = request_payload[0].unpack("C")[0]
        response_packet = if @packets.has_key?(request_type)
                            begin
                              request_packet = @packets[request_type].decode request_payload
                            rescue => e
                              {
                                :"type"       => Packet::SSH_FXP_STATUS::TYPE,
                                :"request-id" => (request_payload[1,4].unpack("N")[0] || 0),
                                :"code"       => Packet::SSH_FXP_STATUS::SSH_FX_BAD_MESSAGE,
                              }
                            else
                              @packets[request_type].respond_to request_packet
                            end
                          else
                            {
                              :"type"       => Packet::SSH_FXP_STATUS::TYPE,
                              :"request-id" => (request_payload[1,4].unpack("N")[0] || 0),
                              :"code"       => Packet::SSH_FXP_STATUS::SSH_FX_OP_UNSUPPORTED,
                            }
                          end
        response_type = response_packet[:"type"]
        @packets[response_type].encode response_packet
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version2/data_type"
require "hrr_rb_sftp/protocol/version2/packet"
