module HrrRbSftp
  class Protocol
    class Version1
      class Packets

        #
        # This class implements SFTP protocol version 1 SSH_FXP_NAME packet type, format, and responder.
        #
        class SSH_FXP_NAME < Packet

          #
          # Represents SSH_FXP_NAME packet type.
          #
          TYPE = 104

          #
          # Represents SSH_FXP_NAME packet format.
          #
          FORMAT = [
            [DataTypes::Byte,   :"type"      ],
            [DataTypes::Uint32, :"request-id"],
            [DataTypes::Uint32, :"count"     ],
          ]

          #
          # Represents SSH_FXP_NAME packet additional format for :"count" => N.
          #
          PER_COUNT_FORMAT = Hash.new{ |hash, key|
            Array.new(key){ |i|
              [
                [DataTypes::String, :"filename[#{i}]"],
                [DataTypes::String, :"longname[#{i}]"],
                [DataTypes::Attrs,  :"attrs[#{i}]"   ],
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
