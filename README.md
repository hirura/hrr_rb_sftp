# HrrRbSftp

[![Build Status](https://travis-ci.com/hirura/hrr_rb_sftp.svg?branch=master)](https://travis-ci.com/hirura/hrr_rb_sftp)
[![Gem Version](https://badge.fury.io/rb/hrr_rb_sftp.svg)](https://badge.fury.io/rb/hrr_rb_sftp)

hrr_rb_sftp is a pure Ruby SFTP server implementation. hrr_rb_sftp now supports SFTP protocol version 1, 2, and 3.

hrr_rb_sftp can be run on SSH 2.0 server like OpenSSH or [hrr_rb_ssh](https://github.com/hirura/hrr_rb_ssh).

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
    - [hrr\_rb\_ssh's SFTP subsystem](#hrr_rb_sshs-sftp-subsystem)
    - [OpenSSH's SFTP subsystem](#opensshs-sftp-subsystem)
- [Note](#note)
- [Supported extensions](#supported-extensions)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hrr_rb_sftp'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install hrr_rb_sftp

## Usage

Here, some typical usage is described, but is not limited to.

### hrr_rb_ssh's SFTP subsystem

hrr_rb_sftp is written in Ruby, so it is straightforward to implement SFTP server on SSH 2.0 server library written in Ruby like hrr_rb_ssh.

There are two ways to work with hrr_rb_ssh, on same process or spawning child process. On both cases, hrr_rb_ssh's request handler mechanism is used.

To run hrr_rb_sftp server on the same process as hrr_rb_ssh is running, the hrr_rb_ssh's request handler is as follows.

```ruby
subsys = HrrRbSsh::Connection::RequestHandler.new { |ctx|
  ctx.chain_proc { |chain|
    case ctx.subsystem_name
    when 'sftp'
      begin
        sftp_server = HrrRbSftp::Server.new(logger: nil)
        sftp_server.start(ctx.io[0], ctx.io[1], ctx.io[2])
        exitstatus = 0
      rescue
        exitstatus = 1
      end
    else
      # Do something for other subsystem, or just return exitstatus
      exitstatus = 0
    end
    exitstatus
  }
}

options['connection_channel_request_subsystem']  = subsys
```

On the other hand, because the arguments for the hrr_rb_sftp server can be standard input, output, and error, so hrr_rb_sftp can be a independent program and be spawned as a child process.

```ruby
subsys = HrrRbSsh::Connection::RequestHandler.new { |ctx|
  ctx.chain_proc { |chain|
    case ctx.subsystem_name
    when 'sftp'
      pid = spawn("/path/to/hrr_rb_sftp_server.rb", {in: ctx.io[0], out: ctx.io[1], err: ctx.io[2]})
      exitstatus = Process.waitpid(pid).to_i
    else
      # Do something for other subsystem, or just return exitstatus
      exitstatus = 0
    end
    exitstatus
  }
}

options['connection_channel_request_subsystem']  = subsys
```

Where, the /path/to/hrr_rb_sftp_server.rb is as follows.

```ruby
#!/usr/bin/env ruby

require "hrr_rb_sftp"

server = HrrRbSftp::Server.new(logger: nil)
server.start($stdin, $stdout, $stderr)
```

### OpenSSH's SFTP subsystem

OpenSSH has capability to run user-defined subsystems. Subsystems that the OpenSSH server recognizes are listed in /etc/ssh/sshd_config file. Usually SFTP subsystem is defined by default to use OpenSSH's SFTP server implementation.

    $ cat /etc/ssh/sshd_config | grep Subsystem
    Subsystem   sftp    /usr/lib/openssh/sftp-server

hrr_rb_sftp can be an alternative with replacing the line in the config file. (After editing the config, reloading or restarting sshd is required.)

    $ cat /etc/ssh/sshd_config | grep Subsystem
    #Subsystem  sftp    /usr/lib/openssh/sftp-server    # Comment out the original line
    Subsystem   sftp    /path/to/hrr_rb_sftp_server.rb

Where, the /path/to/hrr_rb_sftp_server.rb code is the same as shown above.

## Note

- Reversal of SSH_FXP_SYMLINK arguments  
  Because OpenSSH's sftp-server implementation takes SSH_FXP_SYMLINK request linkpath and targetpath arguments in reverse order, this library follows it.  
  The SSH_FXP_SYMLINK request format is as follows:  

  ```
  uint32          id
  string          targetpath
  string          linkpath
  ```

## Supported extensions

The followins extensions are supported.

- hardlink@openssh.com version 1
- fsync@openssh.com version 1

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/hirura/hrr_rb_sftp. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/hirura/hrr_rb_sftp/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the HrrRbSftp project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/hirura/hrr_rb_sftp/blob/master/CODE_OF_CONDUCT.md).
