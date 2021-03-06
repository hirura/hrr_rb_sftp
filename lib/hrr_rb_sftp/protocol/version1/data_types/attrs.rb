module HrrRbSftp
  class Protocol
    module Version1
      module DataTypes

        #
        # This module provides methods to convert file attributes represented in ::Hash and binary string each other.
        #
        class Attrs

          #
          # Represents SSH_FILEXFER_ATTR_SIZE.
          #
          SSH_FILEXFER_ATTR_SIZE        = 0x00000001

          #
          # Represents SSH_FILEXFER_ATTR_UIDGID.
          #
          SSH_FILEXFER_ATTR_UIDGID      = 0x00000002

          #
          # Represents SSH_FILEXFER_ATTR_PERMISSIONS.
          #
          SSH_FILEXFER_ATTR_PERMISSIONS = 0x00000004

          #
          # Represents SSH_FILEXFER_ATTR_ACMODTIME.
          #
          SSH_FILEXFER_ATTR_ACMODTIME   = 0x00000008

          #
          # Represents SSH_FILEXFER_ATTR_EXTENDED.
          #
          SSH_FILEXFER_ATTR_EXTENDED    = 0x80000000

          #
          # Converts file attributes represented in ::Hash into binary string.
          #
          # @param arg [::Hash{::Symbol=>::Object}] File attributes represented in ::Hash to be converted.
          # @raise [::ArgumentError] When arg is not ::Hash value.
          # @return [::String] Converted binary string.
          #
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

            payload  = DataTypes::Uint32.encode flags
            payload += DataTypes::Uint64.encode arg[:"size"]               unless (flags & SSH_FILEXFER_ATTR_SIZE).zero?
            payload += DataTypes::Uint32.encode arg[:"uid"]                unless (flags & SSH_FILEXFER_ATTR_UIDGID).zero?
            payload += DataTypes::Uint32.encode arg[:"gid"]                unless (flags & SSH_FILEXFER_ATTR_UIDGID).zero?
            payload += DataTypes::Uint32.encode arg[:"permissions"]        unless (flags & SSH_FILEXFER_ATTR_PERMISSIONS).zero?
            payload += DataTypes::Uint32.encode arg[:"atime"]              unless (flags & SSH_FILEXFER_ATTR_ACMODTIME).zero?
            payload += DataTypes::Uint32.encode arg[:"mtime"]              unless (flags & SSH_FILEXFER_ATTR_ACMODTIME).zero?
            payload += DataTypes::Uint32.encode arg[:"extensions"].size    unless (flags & SSH_FILEXFER_ATTR_EXTENDED).zero?
            payload += DataTypes::ExtensionPairs.encode arg[:"extensions"] unless (flags & SSH_FILEXFER_ATTR_EXTENDED).zero?
            payload
          end

          #
          # Converts binary string into file attributes represented in ::Hash.
          #
          # @param io [::IO] ::IO instance that has buffer to be read.
          # @return [::Hash{::Symbol=>::Object}] Converted file attributes represented in ::Hash.
          #
          def self.decode io
            attrs = Hash.new
            flags                 = DataTypes::Uint32.decode(io)
            attrs[:"size"]        = DataTypes::Uint64.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_SIZE).zero?
            attrs[:"uid"]         = DataTypes::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_UIDGID).zero?
            attrs[:"gid"]         = DataTypes::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_UIDGID).zero?
            attrs[:"permissions"] = DataTypes::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_PERMISSIONS).zero?
            attrs[:"atime"]       = DataTypes::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_ACMODTIME).zero?
            attrs[:"mtime"]       = DataTypes::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_ACMODTIME).zero?
            extended_count        = DataTypes::Uint32.decode(io)                                   unless (flags & SSH_FILEXFER_ATTR_EXTENDED).zero?
            attrs[:"extensions"]  = Array.new(extended_count){DataTypes::ExtensionPair.decode(io)} unless (flags & SSH_FILEXFER_ATTR_EXTENDED).zero?
            attrs
          end
        end
      end
    end
  end
end

