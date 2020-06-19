module HrrRbSftp

  #
  # This class implements SFTP protocol operations.
  #
  class Protocol
    include Loggable

    #
    # @return [Array] A list of SFTP protocol versions that the library supports.
    #
    def self.versions
      constants.select{|c| c.to_s.start_with?("Version")}.map{|c| const_get(c)}.map{|klass| klass::PROTOCOL_VERSION}
    end

    #
    # @return [Array] A list of extensions that the library supports.
    #
    def self.list_extensions version
      version_class = self.const_get(:"Version#{version}")
      if version_class.const_defined?(:Extension)
        extension_modules = version_class::Extension.constants.map{|c| version_class::Extension.const_get(c)}.select{|m| m.const_defined?(:EXTENSION_NAME)}
        extension_modules.map{|m| {:"extension-name" => m::EXTENSION_NAME, :"extension-data" => m::EXTENSION_DATA}}
      else
        []
      end
    end

    #
    # @param logger [Logger] logger.
    #
    def initialize version, logger: nil
      self.logger = logger

      @version = version
      @version_class = self.class.const_get(:"Version#{@version}")
      @context = Hash.new
      @context[:handles] = Hash.new
      packet_classes = @version_class::Packet.constants.select{|c| c.to_s.start_with?("SSH_FXP_")}.map{|c| @version_class::Packet.const_get(c)}
      @packets = packet_classes.map{|pkt| [pkt::TYPE, pkt.new(@context, logger: logger)]}.inject(Hash.new){|h,(k,v)| h.update({k => v})}
    end

    #
    # Responds to a request.
    #
    # @param request_payload [String] Request payload.
    # @return [String] Response payload that is encoded packet generated by each SFTP protocol version and each request responder.
    #                  When the SFTP protocol version does not support or the library does not implement the request type, the response is SSH_FXP_STATUS with SSH_FX_OP_UNSUPPORTED code.
    #                  When an error occured, the response is SSH_FXP_STATUS with SSH_FX_BAD_MESSAGE code.
    #
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

    #
    # Closes opened and not closed handles.
    #
    def close_handles
      log_info { "closing handles" }
      @context[:handles].each do |k, v|
        v.close rescue nil
      end
      @context[:handles].clear
      log_info { "handles closed" }
    end
  end
end

require "hrr_rb_sftp/protocol/common"
require "hrr_rb_sftp/protocol/version1"
require "hrr_rb_sftp/protocol/version2"
require "hrr_rb_sftp/protocol/version3"
