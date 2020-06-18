#
# hrr_rb_sftp is a pure Ruby SFTP server implementation.
# hrr_rb_sftp now supports SFTP protocol version 1, 2, and 3.
# hrr_rb_sftp can be run on SSH 2.0 server like OpenSSH or hrr_rb_ssh.
#
# It is straightforward to implement SFTP server on SSH 2.0 server library written in Ruby like hrr_rb_ssh.
# There are two ways to work with hrr_rb_ssh, on same process or spawning child process.
# On both cases, hrr_rb_ssh's request handler mechanism is used.
#
# To run hrr_rb_sftp server on the same process that hrr_rb_ssh is running, instantiate and start the hrr_rb_sftp server in a sftp subsystem request.
# On the other hand, because the arguments for the hrr_rb_sftp server can be standard input, output, and error, so hrr_rb_sftp can be a independent program and be spawned as a child process.
#
# OpenSSH has capability to run user-defined subsystems. Subsystems that the OpenSSH server recognizes are listed in /etc/ssh/sshd_config file.
# Usually SFTP subsystem is defined by default to use OpenSSH's SFTP server implementation.
# hrr_rb_sftp can be an alternative with replacing the line in the config file. (After editing the config, reloading or restarting sshd is required.)
#
# The following extensions are supported.
#   - hardlink@openssh.com
#   - fsync@openssh.com
#   - posix-rename@openssh.com
#   - lsetstat@openssh.com
#
# @note
#   - Reversal of SSH_FXP_SYMLINK arguments  
#     Because OpenSSH's sftp-server implementation takes SSH_FXP_SYMLINK request linkpath and targetpath arguments in reverse order, this library follows it.  
#     The SSH_FXP_SYMLINK request format is as follows:  
# 
#       uint32          id
#       string          targetpath
#       string          linkpath
#
# @example On the same process that hrr_rb_ssh is running
#   subsys = HrrRbSsh::Connection::RequestHandler.new { |ctx|
#     ctx.chain_proc { |chain|
#       case ctx.subsystem_name
#       when 'sftp'
#         begin
#           sftp_server = HrrRbSftp::Server.new(logger: nil)
#           sftp_server.start(ctx.io[0], ctx.io[1], ctx.io[2])
#           exitstatus = 0
#         rescue
#           exitstatus = 1
#         end
#       else
#         # Do something for other subsystem, or just return exitstatus
#         exitstatus = 0
#       end
#       exitstatus
#     }
#   }
#   options['connection_channel_request_subsystem']  = subsys
#
# @example Spawnning SFTP server process
#   subsys = HrrRbSsh::Connection::RequestHandler.new { |ctx|
#     ctx.chain_proc { |chain|
#       case ctx.subsystem_name
#       when 'sftp'
#         pid = spawn("/path/to/hrr_rb_sftp_server.rb", {in: ctx.io[0], out: ctx.io[1], err: ctx.io[2]})
#         exitstatus = Process.waitpid(pid).to_i
#       else
#         # Do something for other subsystem, or just return exitstatus
#         exitstatus = 0
#       end
#       exitstatus
#     }
#   }
#   options['connection_channel_request_subsystem']  = subsys
#
# @example hrr_rb_sftp_server.rb
#   #!/usr/bin/env ruby
#   require "hrr_rb_sftp"
#   server = HrrRbSftp::Server.new(logger: nil)
#   server.start($stdin, $stdout, $stderr)
#
# @example Replacing OpenSSH's sftp-server
#   $ cat /etc/ssh/sshd_config | grep Subsystem
#   #Subsystem  sftp    /usr/lib/openssh/sftp-server    # Comment out the original line
#   Subsystem   sftp    /path/to/hrr_rb_sftp_server.rb
#
module HrrRbSftp
end

require "stringio"
require "etc"

require "hrr_rb_sftp/version"
require "hrr_rb_sftp/loggable"
require "hrr_rb_sftp/protocol"
require "hrr_rb_sftp/receiver"
require "hrr_rb_sftp/sender"
require "hrr_rb_sftp/server"
