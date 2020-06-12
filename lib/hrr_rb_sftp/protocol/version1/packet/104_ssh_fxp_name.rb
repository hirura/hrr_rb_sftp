module HrrRbSftp
  class Protocol
    class Version1
      module Packet

        #
        # This class implements SFTP protocol version 1 SSH_FXP_NAME packet type, format, and responder.
        #
        class SSH_FXP_NAME
          include Common::Packetable

          #
          # Represents SSH_FXP_NAME packet type.
          #
          TYPE = 104

          #
          # Represents SSH_FXP_NAME packet format.
          #
          FORMAT = [
            [DataType::Byte,   :"type"      ],
            [DataType::Uint32, :"request-id"],
            [DataType::Uint32, :"count"     ],
          ]

          #
          # Represents SSH_FXP_NAME packet additional format for :"count" => N.
          #
          PER_COUNT_FORMAT = Hash.new{ |hash, key|
            Array.new(key){ |i|
              [
                [DataType::String, :"filename[#{i}]"],
                [DataType::String, :"longname[#{i}]"],
                [DataType::Attrs,  :"attrs[#{i}]"   ],
              ]
            }.inject(:+)
          }

          #
          # Represents SSH_FXP_NAME packet conditional format.
          #
          CONDITIONAL_FORMAT = {
            :"count" => PER_COUNT_FORMAT,
          }
        end
      end
    end
  end
end
