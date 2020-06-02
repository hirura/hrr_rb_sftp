module HrrRbSftp
  class Protocol
    class Version2
      module Packet
        include Version1::Packet

        def self.list
          constants.select{|c| c.to_s.start_with?("SSH_FXP_")}.map{|c| const_get(c)}
        end
      end
    end
  end
end
