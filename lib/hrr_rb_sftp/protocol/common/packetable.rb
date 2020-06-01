module HrrRbSftp
  class Protocol
    module Common
      module Packetable
        include Loggable

        def initialize logger: nil
          self.logger = logger
        end

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

        def decode payload
          payload_io = StringIO.new payload
          format = common_format
          decoded_packet = decode_recursively(payload_io).inject(Hash.new){ |h, (k, v)| h.update({k => v}) }
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
            a + (self.class::CONDITIONAL_FORMAT.fetch(field_name, {})[field_value] || [])
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
