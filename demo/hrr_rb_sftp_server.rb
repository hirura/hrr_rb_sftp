#!/usr/bin/env ruby

require "logger"

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

logger = Logger.new(File.join(File.dirname(__FILE__), "hrr_rb_sftp_server.log"))
logger.level = Logger::INFO
logger.formatter = MyLoggerFormatter.new

server = HrrRbSftp::Server.new(logger: logger)
server.start $stdin, $stdout, $stderr
