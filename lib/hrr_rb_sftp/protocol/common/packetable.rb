module HrrRbSftp
  class Protocol
    module Common

      #
      # This module implements common packet operations and is to be included in each packet class.
      #
      module Packetable
        include Loggable

        #
        # Returns a new instance of a class that includes this module.
        #
        # @param context [Hash] Contextual variables.
        #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
        #   - :extensions (Extensions) - An instance of Extensions.
        # @param logger [Logger] Logger.
        #
        def initialize context, logger: nil
          self.logger = logger

          @context = context
        end

        #
        # Returns contextual variables.
        #
        # @return [Hash] Contextual variables.
        #   - :handles (Hash\\{String=>File, Dir\}) - Opened handles.
        #   - :extensions (Extensions) - An instance of Extensions.
        #
        def context
          @context
        end

        #
        # Returns opened handles.
        #
        # @return [Hash{String=>File, Dir}] Opened handles.
        #
        def handles
          @context[:handles]
        end

        #
        # Returns An instance of Extensions.
        #
        # @return [Extensions] An instance of Extensions.
        #
        def extensions
          @context[:extensions]
        end

        #
        # Encodes packet represented in Hash into payload represented in binary string.
        #
        # @param packet [Hash{Symbol=>Object}] Packet represented in Hash that key and value are field name and field value.
        # @return [String] Encoded payload converted from packet.
        #
        def encode packet
          log_debug { 'encoding packet: ' + packet.inspect }
          format = common_format + conditional_format(packet)
          format.map{ |data_type, field_name|
            begin
              field_value = packet[field_name]
              data_type.encode field_value
            rescue => e
              log_debug { "'field_name', 'field_value': #{field_name.inspect}, #{field_value.inspect}" }
              raise e
            end
          }.join
        end

        #
        # Decodes payload represented in binary string into packet represented in Hash.
        #
        # @param payload [String] Payload of binary string.
        # @param complementary_packet [Hash{Symbol=>Object}] Implied fields that activate conditional format. Now this is used for debug purpose.
        # @return [String] Decoded packet represented in Hash that key and value are field name and field value.
        #
        def decode payload, complementary_packet={}
          payload_io = StringIO.new payload
          format = common_format
          decoded_packet = decode_recursively(payload_io).inject(Hash.new){ |h, (k, v)| h.update({k => v}) }
          if complementary_packet.any?
            decoded_packet.merge! decode_recursively(payload_io, complementary_packet.to_a).inject(Hash.new){ |h, (k, v)| h.update({k => v}) }
          end
          log_debug { 'decoded packet: ' + decoded_packet.inspect }
          decoded_packet
        end

        private

        def common_format
          self.class::FORMAT
        end

        def conditional_format packet
          return [] unless self.class.const_defined? :CONDITIONAL_FORMAT
          packet.inject([]){ |a, (field_name, field_value)|
            a + ((self.class::CONDITIONAL_FORMAT[field_name] || {})[field_value] || [])
          }
        end

        def decode_recursively payload_io, packet=nil
          if packet.class == Array and packet.size == 0
            []
          else
            format = case packet
                     when nil
                       common_format
                     when Array
                       conditional_format(packet)
                     end
            decoded_packet = format.map{ |data_type, field_name|
              begin
                [field_name, data_type.decode(payload_io)]
              rescue => e
                log_debug { "'field_name': #{field_name.inspect}" }
                raise e
              end
            }
            decoded_packet + decode_recursively(payload_io, decoded_packet)
          end
        end
      end
    end
  end
end
