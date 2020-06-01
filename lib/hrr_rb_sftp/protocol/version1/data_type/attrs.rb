module HrrRbSftp
  class Protocol
    class Version1
      module DataType
        class Attrs
          SSH_FILEXFER_ATTR_SIZE        = 0x00000001
          SSH_FILEXFER_ATTR_UIDGID      = 0x00000002
          SSH_FILEXFER_ATTR_PERMISSIONS = 0x00000004
          SSH_FILEXFER_ATTR_ACMODTIME   = 0x00000008
          SSH_FILEXFER_ATTR_EXTENDED    = 0x80000000

          def self.encode arg
            unless arg.kind_of? ::Hash
              raise ArgumentError, "must be a kind of Hash, but got #{arg.inspect}"
            end

            flags = 0
            flags |= SSH_FILEXFER_ATTR_SIZE        if arg.has_key?(:"size")
            flags |= SSH_FILEXFER_ATTR_UIDGID      if arg.has_key?(:"uid") && arg.has_key?(:"gid")
            flags |= SSH_FILEXFER_ATTR_PERMISSIONS if arg.has_key?(:"permissions")
            flags |= SSH_FILEXFER_ATTR_ACMODTIME   if arg.has_key?(:"atime") && arg.has_key?(:"mtime")
            flags |= SSH_FILEXFER_ATTR_EXTENDED    if arg.has_key?(:"extensions")

            payload  = DataType::Uint32.encode flags
            payload += DataType::Uint64.encode arg[:"size"]               unless (flags & SSH_FILEXFER_ATTR_SIZE).zero?
            payload += DataType::Uint32.encode arg[:"uid"]                unless (flags & SSH_FILEXFER_ATTR_UIDGID).zero?
            payload += DataType::Uint32.encode arg[:"gid"]                unless (flags & SSH_FILEXFER_ATTR_UIDGID).zero?
            payload += DataType::Uint32.encode arg[:"permissions"]        unless (flags & SSH_FILEXFER_ATTR_PERMISSIONS).zero?
            payload += DataType::Uint32.encode arg[:"atime"]              unless (flags & SSH_FILEXFER_ATTR_ACMODTIME).zero?
            payload += DataType::Uint32.encode arg[:"mtime"]              unless (flags & SSH_FILEXFER_ATTR_ACMODTIME).zero?
            payload += DataType::Uint32.encode arg[:"extensions"].size    unless (flags & SSH_FILEXFER_ATTR_EXTENDED).zero?
            payload += DataType::ExtensionPairs.encode arg[:"extensions"] unless (flags & SSH_FILEXFER_ATTR_EXTENDED).zero?
            payload
          end

          def self.decode io
            attrs = Hash.new
            flags                 = DataType::Uint32.decode(io)
            attrs[:"size"]        = DataType::Uint64.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_SIZE).zero?
            attrs[:"uid"]         = DataType::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_UIDGID).zero?
            attrs[:"gid"]         = DataType::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_UIDGID).zero?
            attrs[:"permissions"] = DataType::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_PERMISSIONS).zero?
            attrs[:"atime"]       = DataType::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_ACMODTIME).zero?
            attrs[:"mtime"]       = DataType::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_ACMODTIME).zero?
            extended_count        = DataType::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_EXTENDED).zero?
            attrs[:"extensions"]  = Array.new(extended_count){DataType::ExtensionPair.decode(io)} unless (flags & SSH_FILEXFER_ATTR_EXTENDED).zero?
            attrs
          end
        end
      end
    end
  end
end

