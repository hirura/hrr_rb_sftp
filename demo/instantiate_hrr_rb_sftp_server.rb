require 'logger'
require 'socket'
require 'hrr_rb_ssh'

begin
  require 'hrr_rb_sftp'
rescue LoadError
  $:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
  require 'hrr_rb_sftp'
end

class MyLoggerFormatter < ::Logger::Formatter
  def call severity, time, progname, msg
    "%s, [%s#%d.%x] %5s -- %s: %s\n" % [severity[0..0], format_datetime(time), Process.pid, Thread.current.object_id, severity, progname, msg2str(msg)]
  end
end

logger = Logger.new(File.join(File.dirname(__FILE__), "instantiate_hrr_rb_sftp_server.log"))
logger.level = Logger::INFO
logger.formatter = MyLoggerFormatter.new

auth_publickey = HrrRbSsh::Authentication::Authenticator.new { |ctx|
  true # accept any user
}

conn_subsys = HrrRbSsh::Connection::RequestHandler.new { |ctx|
  ctx.chain_proc { |chain|
    case ctx.subsystem_name
    when 'sftp'
      sftp_server = HrrRbSftp::Server.new(logger: logger)
      sftp_server.start(ctx.io[0], ctx.io[1], ctx.io[2])
      exitstatus = 0
    else
      exitstatus = 1
    end
    exitstatus
  }
}

options = {}
options['authentication_publickey_authenticator'] = auth_publickey
options['connection_channel_request_subsystem']   = conn_subsys

server = TCPServer.new 10022
while true
  Thread.new(server.accept) do |io|
    begin
      pid = fork do
        begin
          ssh_server = HrrRbSsh::Server.new(options, logger: logger)
          ssh_server.start io
        rescue => e
          logger.error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
          exit false
        end
      end
      logger.info { "process #{pid} started" }
      io.close rescue nil
      pid, status = Process.waitpid2(pid)
    rescue => e
      logger.error { [e.backtrace[0], ": ", e.message, " (", e.class.to_s, ")\n\t", e.backtrace[1..-1].join("\n\t")].join }
    ensure
      status ||= nil
      logger.info { "process #{pid} finished with status #{status.inspect}" }
    end
  end
end
