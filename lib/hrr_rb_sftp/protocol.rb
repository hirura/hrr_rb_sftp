module HrrRbSftp
  class Protocol
    include Loggable

    def self.versions
      constants.select{|c| c.to_s.start_with?("Version")}.map{|c| const_get(c)}.map{|klass| klass::PROTOCOL_VERSION}
    end

    def initialize version, logger: nil
      self.logger = logger

      @handles = Hash.new
      @version = version
      @version_class = self.class.const_get(:"Version#{@version}")
      packet_classes = @version_class::Packet.constants.select{|c| c.to_s.start_with?("SSH_FXP_")}.map{|c| @version_class::Packet.const_get(c)}
      @packets = packet_classes.map{|pkt| [pkt::TYPE, pkt.new(@handles, logger: logger)]}.inject(Hash.new){|h,(k,v)| h.update({k => v})}
    end

    def respond_to request_payload
      request_type = request_payload[0].unpack("C")[0]
      response_packet = if @packets.has_key?(request_type)
                          begin
                            request_packet = @packets[request_type].decode request_payload
                          rescue => e
                            {
                              :"type"          => @version_class::Packet::SSH_FXP_STATUS::TYPE,
                              :"request-id"    => (request_payload[1,4].unpack("N")[0] || 0),
                              :"code"          => @version_class::Packet::SSH_FXP_STATUS::SSH_FX_BAD_MESSAGE,
                              :"error message" => e.message,
                              :"language tag"  => "",
                            }
                          else
                            @packets[request_type].respond_to request_packet
                          end
                        else
                          {
                            :"type"          => @version_class::Packet::SSH_FXP_STATUS::TYPE,
                            :"request-id"    => (request_payload[1,4].unpack("N")[0] || 0),
                            :"code"          => @version_class::Packet::SSH_FXP_STATUS::SSH_FX_OP_UNSUPPORTED,
                            :"error message" => "Unsupported type: #{request_type}",
                            :"language tag"  => "",
                          }
                        end
      response_type = response_packet[:"type"]
      @packets[response_type].encode response_packet
    end

    def close_handles
      log_info { "closing handles" }
      @handles.each do |k, v|
        v.close rescue nil
      end
      @handles.clear
      log_info { "handles closed" }
    end
  end
end

require "hrr_rb_sftp/protocol/common"
require "hrr_rb_sftp/protocol/version1"
require "hrr_rb_sftp/protocol/version2"
require "hrr_rb_sftp/protocol/version3"
