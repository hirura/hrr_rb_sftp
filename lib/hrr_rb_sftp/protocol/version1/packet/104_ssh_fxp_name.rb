module HrrRbSftp
  class Protocol
    class Version1
      module Packet
        class SSH_FXP_NAME
          include Common::Packetable

          TYPE = 104

          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::Uint32, :"count"     ],
          ]

          PER_COUNT_FORMAT = Hash.new{ |hash, key|
            Array.new(key){ |i|
              [
                [DataType::String, :"filename[#{i}]"],
                [DataType::String, :"longname[#{i}]"],
                [DataType::Attrs,  :"attrs[#{i}]"   ],
              ]
            }.inject(:+)
          }

          CONDITIONAL_FORMAT = {
            :"count" => PER_COUNT_FORMAT,
          }
        end
      end
    end
  end
end
