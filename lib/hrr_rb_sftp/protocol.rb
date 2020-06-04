module HrrRbSftp
  class Protocol
    include Loggable

    def self.versions
      constants.select{|c| c.to_s.start_with?("Version")}.map{|c| const_get(c)}.map{|klass| klass::PROTOCOL_VERSION}
    end

    def initialize version, logger: nil
      self.logger = logger

      @version = version
      @version_class = self.class.const_get(:"Version#{@version}")
      @packets = @version_class::Packet.constants.select{|c| c.to_s.start_with?("SSH_FXP_")}.map{|c| @version_class::Packet.const_get(c)}.map{|pkt| [pkt::TYPE, pkt.new(logger: logger)]}.inject(Hash.new){|h,(k,v)| h.update({k => v})}
    end

    def respond_to request_payload
      request_type = request_payload[0].unpack("C")[0]
      response_packet = if @packets.has_key?(request_type)
                          begin
                            request_packet = @packets[request_type].decode request_payload
                          rescue => e
                            {
                              :"type"       => @version_class::Packet::SSH_FXP_STATUS::TYPE,
                              :"request-id" => (request_payload[1,4].unpack("N")[0] || 0),
                              :"code"       => @version_class::Packet::SSH_FXP_STATUS::SSH_FX_BAD_MESSAGE,
                            }
                          else
                            @packets[request_type].respond_to request_packet
                          end
                        else
                          {
                            :"type"       => @version_class::Packet::SSH_FXP_STATUS::TYPE,
                            :"request-id" => (request_payload[1,4].unpack("N")[0] || 0),
                            :"code"       => @version_class::Packet::SSH_FXP_STATUS::SSH_FX_OP_UNSUPPORTED,
                          }
                        end
      response_type = response_packet[:"type"]
      @packets[response_type].encode response_packet
    end
  end
end

require "hrr_rb_sftp/protocol/common"
require "hrr_rb_sftp/protocol/version1"
require "hrr_rb_sftp/protocol/version2"
