module HrrRbSftp
  class Protocol
    class Version1
      module DataType
        include Common::DataType
      end
    end
  end
end

require "hrr_rb_sftp/protocol/version1/data_type/attrs"
