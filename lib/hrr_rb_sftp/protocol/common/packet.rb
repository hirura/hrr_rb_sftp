module HrrRbSftp
  module Protocol
    module Common
      class Packet
        include Loggable

        def initialize logger: nil
          self.logger = logger
        end

        def encode packet
          log_debug { 'encoding packet: ' + packet.inspect }
          format = common_format
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
          decoded_packet = format.map{ |data_type, field_name|
            begin
              [field_name, data_type.decode(payload_io)]
            rescue => e
              log_debug { "'field_name': #{field_name.inspect}" }
              raise e
            end
          }.inject(Hash.new){ |h, (k, v)| h.update({k => v}) }
          log_debug { 'decoded packet: ' + decoded_packet.inspect }
          decoded_packet
        end

        private

        def common_format
          self.class::FORMAT
        end
      end
    end
  end
end
