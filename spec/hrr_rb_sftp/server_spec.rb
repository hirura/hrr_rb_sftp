RSpec.describe HrrRbSftp::Server do
  let(:io){
    io_in  = IO.pipe
    io_out = IO.pipe
    io_err = IO.pipe
    Struct.new(:local, :remote).new(
      Struct.new(:in, :out, :err).new(io_in[0], io_out[1], io_err[1]),
      Struct.new(:in, :out, :err).new(io_in[1], io_out[0], io_err[0])
    )
  }

  let(:logger){
    if ENV["LOGGING"]
      require "logger"
      logger = Logger.new $stdout
      logger.level = ENV["LOGGING"]
      logger
    end
  }

  after :example do
    io.remote.in.close  rescue nil
    io.local.in.close   rescue nil
    io.local.out.close  rescue nil
    io.remote.out.close rescue nil
    io.local.err.close  rescue nil
    io.remote.err.close rescue nil
  end

  describe ".new" do
    it "takes no argument" do
      expect{ described_class.new logger: logger }.not_to raise_error
    end
  end

  describe "#start" do
    let(:server){
      described_class.new logger: logger
    }

    [1, 2, 3].each do |version|
      context "when remote protocol version is #{version}" do
        it "takes in, out, err arguments and starts negotiating version then responds to requests" do
          expect( server ).to receive(:negotiate_version).with(no_args).and_return(version).once
          expect( server ).to receive(:respond_to_requests).with(no_args).once
          expect( server ).to receive(:close_handles).with(no_args).once
          expect{ server.start *io.local.to_a }.not_to raise_error
        end

        it "takes in, out, and no err arguments and starts negotiating version then responds to requests" do
          expect( server ).to receive(:negotiate_version).with(no_args).and_return(version).once
          expect( server ).to receive(:respond_to_requests).with(no_args).once
          expect( server ).to receive(:close_handles).with(no_args).once
          expect{ server.start *(io.local.to_a[0,2]) }.not_to raise_error
        end

        it "calls @protocol#close_handles even when #respond_to_requests raises an error" do
          expect( server ).to receive(:negotiate_version).with(no_args).and_return(version).once
          expect( server ).to receive(:respond_to_requests).with(no_args).and_raise(RuntimeError, "dummy error").once
          expect( server ).to receive(:close_handles).with(no_args).once
          expect{ server.start *io.local.to_a }.to raise_error RuntimeError, "dummy error"
        end
      end
    end

    it "raises an error when less than 2 arguments" do
      expect{ server.start "arg1" }.to raise_error ArgumentError
    end

    it "raises an error when more than 3 arguments" do
      expect{ server.start "arg1", "arg2", "arg3", "arg4" }.to raise_error ArgumentError
    end
  end

  describe "#negotiate_version" do
    context "when input IO is closed before receiving SSH_FXP_INIT" do
      it "raises an error when failed receiving SSH_FXP_INIT" do
        io.remote.in.close
        expect{ described_class.new(logger: logger).start *io.local.to_a }.to raise_error RuntimeError, "Failed receiving SSH_FXP_INIT"
      end
    end

    context "when receiving valid SSH_FXP_INIT" do
      let(:init_packet){
        {
          :"type"    => HrrRbSftp::Protocol::Common::Packet::SSH_FXP_INIT::TYPE,
          :"version" => version,
        }
      }
      let(:init_payload){
        HrrRbSftp::Protocol::Common::Packet::SSH_FXP_INIT.new({}).encode(init_packet)
      }

      before :example do
        @thread = Thread.new{
          server = described_class.new logger: logger
          server.start *io.local.to_a
        }
      end

      after :example do
        @thread.kill
      end

      [1, 2, 3].each do |version|
        context "when remote protocol version is #{version}" do
          let(:version){ version }

          it "receives init with version #{version} and returns version with version #{version}" do
            io.remote.in.write ([init_payload.bytesize].pack("N") + init_payload)
            payload_length = io.remote.out.read(4).unpack("N")[0]
            payload = io.remote.out.read(payload_length)
            expect( payload[0].unpack("C")[0] ).to eq HrrRbSftp::Protocol::Common::Packet::SSH_FXP_VERSION::TYPE
            packet = HrrRbSftp::Protocol::Common::Packet::SSH_FXP_VERSION.new({}).decode(payload)
            expect( packet[:"version"]    ).to eq version
            if version < 3
              expect( packet[:"extensions"] ).to eq []
            else
              expect( packet[:"extensions"] ).to eq [{:"extension-name"=>"hardlink@openssh.com", :"extension-data"=>"1"}]
            end
          end
        end
      end
    end
  end

  describe "#respond_to_requests" do
    let(:init_packet){
      {
        :"type"    => HrrRbSftp::Protocol::Common::Packet::SSH_FXP_INIT::TYPE,
        :"version" => version,
      }
    }
    let(:init_payload){
      HrrRbSftp::Protocol::Common::Packet::SSH_FXP_INIT.new({}).encode(init_packet)
    }

    let(:server){ described_class.new logger: logger }

    before :example do
      io.remote.in.write ([init_payload.bytesize].pack("N") + init_payload)
    end

    [1, 2, 3].each do |version|
      context "when remote protocol version is #{version}" do
        let(:version){ version }

        context "when input IO is closed before receiving packet length" do
          before :example do
            io.remote.in.close
          end

          it "is finished then calls close_handles" do
            expect( server ).to receive(:close_handles).with(no_args).once
            server.start *io.local.to_a
          end
        end

        context "when input IO is closed just after receiving packet length" do
          before :example do
            io.remote.in.write [1].pack("N")
            io.remote.in.close
          end

          it "is finished then calls close_handles" do
            expect( server ).to receive(:close_handles).with(no_args).once
            server.start *io.local.to_a
          end
        end

        context "when input IO is closed during receiving payload" do
          before :example do
            io.remote.in.write [2].pack("N")
            io.remote.in.write "a"
            io.remote.in.close
          end

          it "is finished then calls close_handles" do
            expect( server ).to receive(:close_handles).with(no_args).once
            server.start *io.local.to_a
          end
        end
      end
    end
  end

  describe "#close_handles" do
    let(:server){ described_class.new logger: logger }
    let(:protocol){ double("protocol") }

    before :example do
      server.instance_variable_set(:"@protocol", protocol)
    end

    it "calls @protocol#close_handles" do
      expect( protocol ).to receive(:close_handles).with(no_args).once
      server.send(:close_handles)
    end
  end

  describe "request and response loop" do
    let(:init_packet){
      {
        :"type"    => HrrRbSftp::Protocol::Common::Packet::SSH_FXP_INIT::TYPE,
        :"version" => version,
      }
    }
    let(:init_payload){
      HrrRbSftp::Protocol::Common::Packet::SSH_FXP_INIT.new({}).encode(init_packet)
    }

    before :example do
      @thread = Thread.new{
        server = described_class.new logger: logger
        server.start *io.local.to_a
      }
      io.remote.in.write ([init_payload.bytesize].pack("N") + init_payload)
      payload_length = io.remote.out.read(4).unpack("N")[0]
      payload = io.remote.out.read(payload_length)
    end

    after :example do
      @thread.kill
    end

    [1, 2, 3].each do |version|
      context "when remote protocol version is #{version}" do
        let(:version){ version }
        let(:version_class){ HrrRbSftp::Protocol.const_get(:"Version#{version}") }

        context "when request type is invalid" do
          let(:realpath_payload){
            [
              type,
              request_id,
            ].pack("CN")
          }
          let(:type){ 0 }
          let(:request_id){ 1 }

          it "returns status response" do
            io.remote.in.write ([realpath_payload.bytesize].pack("N") + realpath_payload)
            payload_length = io.remote.out.read(4).unpack("N")[0]
            payload = io.remote.out.read(payload_length)
            expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
            packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
            expect( packet[:"request-id"] ).to eq request_id
            expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OP_UNSUPPORTED
            if version >= 3
              expect( packet[:"error message"] ).to eq "Unsupported type: #{type}"
              expect( packet[:"language tag"]  ).to eq ""
            end
          end
        end

        context "when request does not have request-id" do
          let(:realpath_payload){
            [
              version_class::Packet::SSH_FXP_REALPATH::TYPE,
            ].pack("C")
          }

          it "returns status response" do
            io.remote.in.write ([realpath_payload.bytesize].pack("N") + realpath_payload)
            payload_length = io.remote.out.read(4).unpack("N")[0]
            payload = io.remote.out.read(payload_length)
            expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
            packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
            expect( packet[:"request-id"] ).to eq 0
            expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_BAD_MESSAGE
            if version >= 3
              expect( packet[:"error message"] ).to eq "undefined method `unpack' for nil:NilClass"
              expect( packet[:"language tag"]  ).to eq ""
            end
          end
        end

        context "when request does not have some fields" do
          let(:realpath_payload){
            [
              version_class::Packet::SSH_FXP_REALPATH::TYPE,
              request_id,
            ].pack("CN")
          }
          let(:request_id){ 1 }

          it "returns status response" do
            io.remote.in.write ([realpath_payload.bytesize].pack("N") + realpath_payload)
            payload_length = io.remote.out.read(4).unpack("N")[0]
            payload = io.remote.out.read(payload_length)
            expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
            packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
            expect( packet[:"request-id"] ).to eq request_id
            expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_BAD_MESSAGE
            if version >= 3
              expect( packet[:"error message"] ).to eq "undefined method `unpack' for nil:NilClass"
              expect( packet[:"language tag"]  ).to eq ""
            end
          end
        end

        context "when responding to open request" do
          let(:open_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_OPEN::TYPE,
              :"request-id" => request_id,
              :"filename"   => filename,
              :"pflags"     => pflags,
              :"attrs"      => attrs,
            }
          }
          let(:open_payload){
            version_class::Packet::SSH_FXP_OPEN.new({}).encode(open_packet)
          }
          let(:request_id){ 1 }
          let(:filename){ "filename" }
          let(:handle){ "handle" }

          context "with SSH_FXF_READ flag" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }
            let(:attrs){ {} }

            it "returns handle response" do
              expect(::File).to receive(:open).with(filename, ::File::RDONLY).and_return(handle)
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq request_id
              expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
            end
          end

          context "with SSH_FXF_WRITE flag" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE }

            context "without permissions attribute" do
              let(:attrs){ {} }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::WRONLY).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end

            context "with permissions attribute" do
              let(:attrs){ {:"permissions" => permissions} }
              let(:permissions){ 0644 }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::WRONLY).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end
          end

          context "with SSH_FXF_READ and SSH_FXF_WRITE flags" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE }

            context "without permissions attribute" do
              let(:attrs){ {} }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::RDWR).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end

            context "with permissions attribute" do
              let(:attrs){ {:"permissions" => permissions} }
              let(:permissions){ 0644 }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::RDWR).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end
          end

          context "with SSH_FXF_WRITE and SSH_FXF_APPEND flags" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_APPEND }

            context "without permissions attribute" do
              let(:attrs){ {} }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::WRONLY | ::File::APPEND).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end

            context "with permissions attribute" do
              let(:attrs){ {:"permissions" => permissions} }
              let(:permissions){ 0644 }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::WRONLY | ::File::APPEND).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end
          end

          context "with SSH_FXF_WRITE and SSH_FXF_CREAT flags" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_CREAT }
            context "without permissions attribute" do
              let(:attrs){ {} }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::WRONLY | ::File::CREAT).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end

            context "with permissions attribute" do
              let(:attrs){ {:"permissions" => permissions} }
              let(:permissions){ 0644 }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::WRONLY | ::File::CREAT, permissions).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end
          end

          context "with SSH_FXF_WRITE, SSH_FXF_CREAT, SSH_FXF_TRUNC, and SSH_FXF_EXCL flags" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_CREAT | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_TRUNC | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_EXCL }
            context "without permissions attribute" do
              let(:attrs){ {} }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::WRONLY | ::File::CREAT | ::File::TRUNC | ::File::EXCL).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end

            context "with permissions attribute" do
              let(:attrs){ {:"permissions" => permissions} }
              let(:permissions){ 0644 }

              it "returns handle response" do
                expect(::File).to receive(:open).with(filename, ::File::WRONLY | ::File::CREAT | ::File::TRUNC | ::File::EXCL, permissions).and_return(handle)
                io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
                packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
                expect( packet[:"request-id"]  ).to eq request_id
                expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
              end
            end
          end

          context "when no flag is specified" do
            let(:pflags){ 0 }
            let(:attrs){ {} }

            it "returns status response" do
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "At least SSH_FXF_READ or SSH_FXF_READ must be specified"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when SSH_FXF_TRUNC flag without SSH_FXF_CREAT flag is specified" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_TRUNC }
            let(:attrs){ {} }

            it "returns status response" do
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "SSH_FXF_CREAT MUST also be specified when SSH_FXF_TRUNC is specified"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when SSH_FXF_EXCL flag without SSH_FXF_CREAT flag is specified" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_EXCL }
            let(:attrs){ {} }

            it "returns status response" do
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "SSH_FXF_CREAT MUST also be specified when SSH_FXF_EXCL is specified"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when SSH_FXF_READ flag is specified and the file does not exist" do
            let(:filename){ "does/not/exist" }
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }
            let(:attrs){ {} }

            it "returns status response" do
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
              if version >= 3
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when SSH_FXF_READ flag is specified and the file is not accessible" do
            let(:filename){ "dir000/file" }
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }
            let(:attrs){ {} }

            before :example do
              Dir.mkdir(File.dirname(filename))
              FileUtils.touch(filename)
              FileUtils.chmod(0000, File.dirname(filename))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(filename))
              FileUtils.remove_entry_secure(File.dirname(filename))
            end

            it "returns status response" do
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:filename){ ("a".."z").to_a.join * 10 }
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }
            let(:attrs){ {} }

            it "returns status response" do
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to close request" do
          context "when request is valid" do
            let(:open_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_OPEN::TYPE,
                :"request-id" => open_request_id,
                :"filename"   => filename,
                :"pflags"     => pflags,
                :"attrs"      => attrs,
              }
            }
            let(:open_payload){
              version_class::Packet::SSH_FXP_OPEN.new({}).encode(open_packet)
            }
            let(:open_request_id){ 1 }
            let(:filename){ "filename" }
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }
            let(:attrs){ {} }
            let(:content){ "content" }

            let(:close_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_CLOSE::TYPE,
                :"request-id" => close_request_id,
                :"handle"     => @handle,
              }
            }
            let(:close_payload){
              version_class::Packet::SSH_FXP_CLOSE.new({}).encode(close_packet)
            }
            let(:close_request_id){ 2 }

            before :example do
              File.open(filename, "w"){ |f| f.write content }
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              FileUtils.remove_entry_secure filename
            end

            it "returns status response" do
              io.remote.in.write ([close_payload.bytesize].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq close_request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when specified handle does not exist" do
            let(:close_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_CLOSE::TYPE,
                :"request-id" => close_request_id,
                :"handle"     => handle,
              }
            }
            let(:close_payload){
              version_class::Packet::SSH_FXP_CLOSE.new({}).encode(close_packet)
            }
            let(:close_request_id){ 2 }
            let(:handle){ "handle" }

            it "returns status response" do
              io.remote.in.write ([close_payload.bytesize].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq close_request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "Specified handle does not exist"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to read request" do
          context "when request is valid" do
            let(:open_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_OPEN::TYPE,
                :"request-id" => open_request_id,
                :"filename"   => filename,
                :"pflags"     => pflags,
                :"attrs"      => attrs,
              }
            }
            let(:open_payload){
              version_class::Packet::SSH_FXP_OPEN.new({}).encode(open_packet)
            }
            let(:open_request_id){ 1 }
            let(:filename){ "filename" }
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }
            let(:attrs){ {} }
            let(:content){ "0123456789" }

            let(:close_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_CLOSE::TYPE,
                :"request-id" => close_request_id,
                :"handle"     => @handle,
              }
            }
            let(:close_payload){
              version_class::Packet::SSH_FXP_CLOSE.new({}).encode(close_packet)
            }
            let(:close_request_id){ 20 }

            let(:read_packet_0){
              {
                :"type"       => version_class::Packet::SSH_FXP_READ::TYPE,
                :"request-id" => read_request_id_0,
                :"handle"     => @handle,
                :"offset"     => 0,
                :"len"        => 5,
              }
            }
            let(:read_payload_0){
              version_class::Packet::SSH_FXP_READ.new({}).encode(read_packet_0)
            }
            let(:read_request_id_0){ 10 }

            let(:read_packet_1){
              {
                :"type"       => version_class::Packet::SSH_FXP_READ::TYPE,
                :"request-id" => read_request_id_1,
                :"handle"     => @handle,
                :"offset"     => 5,
                :"len"        => 5,
              }
            }
            let(:read_payload_1){
              version_class::Packet::SSH_FXP_READ.new({}).encode(read_packet_1)
            }
            let(:read_request_id_1){ 11 }

            let(:read_packet_2){
              {
                :"type"       => version_class::Packet::SSH_FXP_READ::TYPE,
                :"request-id" => read_request_id_2,
                :"handle"     => @handle,
                :"offset"     => 10,
                :"len"        => 5,
              }
            }
            let(:read_payload_2){
              version_class::Packet::SSH_FXP_READ.new({}).encode(read_packet_2)
            }
            let(:read_request_id_2){ 12 }

            before :example do
              File.open(filename, "w"){ |f| f.write content }
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              io.remote.in.write ([close_payload.bytesize].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              FileUtils.remove_entry_secure filename
            end

            it "returns data and then EOF status response" do
              io.remote.in.write ([read_payload_0.bytesize].pack("N") + read_payload_0)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_DATA::TYPE
              packet = version_class::Packet::SSH_FXP_DATA.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq read_request_id_0
              expect( packet[:"data"]       ).to eq content[0,5]

              io.remote.in.write ([read_payload_1.bytesize].pack("N") + read_payload_1)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_DATA::TYPE
              packet = version_class::Packet::SSH_FXP_DATA.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq read_request_id_1
              expect( packet[:"data"]       ).to eq content[5,5]

              io.remote.in.write ([read_payload_2.bytesize].pack("N") + read_payload_2)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq read_request_id_2
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_EOF
              if version >= 3
                expect( packet[:"error message"] ).to eq "End of file"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when specified handle does not exist" do
            let(:read_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_READ::TYPE,
                :"request-id" => read_request_id,
                :"handle"     => handle,
                :"offset"     => 0,
                :"len"        => 123,
              }
            }
            let(:read_payload){
              version_class::Packet::SSH_FXP_READ.new({}).encode(read_packet)
            }
            let(:read_request_id){ 10 }
            let(:handle){ "handle" }

            it "returns status response" do
              io.remote.in.write ([read_payload.bytesize].pack("N") + read_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq read_request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "Specified handle does not exist"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to write request" do
          context "when request is valid" do
            let(:open_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_OPEN::TYPE,
                :"request-id" => open_request_id,
                :"filename"   => filename,
                :"pflags"     => pflags,
                :"attrs"      => attrs,
              }
            }
            let(:open_payload){
              version_class::Packet::SSH_FXP_OPEN.new({}).encode(open_packet)
            }
            let(:open_request_id){ 1 }
            let(:filename){ "filename" }
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_CREAT | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_TRUNC }
            let(:attrs){ {} }
            let(:content){ "0123456789" }

            let(:close_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_CLOSE::TYPE,
                :"request-id" => close_request_id,
                :"handle"     => @handle,
              }
            }
            let(:close_payload){
              version_class::Packet::SSH_FXP_CLOSE.new({}).encode(close_packet)
            }
            let(:close_request_id){ 20 }

            let(:write_packet_0){
              {
                :"type"       => version_class::Packet::SSH_FXP_WRITE::TYPE,
                :"request-id" => write_request_id_0,
                :"handle"     => @handle,
                :"offset"     => 0,
                :"data"       => content[0,5],
              }
            }
            let(:write_payload_0){
              version_class::Packet::SSH_FXP_WRITE.new({}).encode(write_packet_0)
            }
            let(:write_request_id_0){ 10 }

            let(:write_packet_1){
              {
                :"type"       => version_class::Packet::SSH_FXP_WRITE::TYPE,
                :"request-id" => write_request_id_1,
                :"handle"     => @handle,
                :"offset"     => 5,
                :"data"       => content[5,5],
              }
            }
            let(:write_payload_1){
              version_class::Packet::SSH_FXP_WRITE.new({}).encode(write_packet_1)
            }
            let(:write_request_id_1){ 11 }

            before :example do
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              FileUtils.remove_entry_secure filename
            end

            it "returns status response" do
              io.remote.in.write ([write_payload_0.bytesize].pack("N") + write_payload_0)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq write_request_id_0
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end

              io.remote.in.write ([write_payload_1.bytesize].pack("N") + write_payload_1)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq write_request_id_1
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end

              io.remote.in.write ([close_payload.bytesize].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq close_request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end

              expect( File.read(filename) ).to eq content
            end
          end

          context "when specified handle does not exist" do
            let(:write_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_WRITE::TYPE,
                :"request-id" => write_request_id,
                :"handle"     => handle,
                :"offset"     => 0,
                :"data"       => "data",
              }
            }
            let(:write_payload){
              version_class::Packet::SSH_FXP_WRITE.new({}).encode(write_packet)
            }
            let(:write_request_id){ 10 }
            let(:handle){ "handle" }

            it "returns status response" do
              io.remote.in.write ([write_payload.bytesize].pack("N") + write_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq write_request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "Specified handle does not exist"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to lstat request" do
          let(:lstat_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_LSTAT::TYPE,
              :"request-id" => request_id,
              :"path"       => path,
            }
          }
          let(:lstat_payload){
            version_class::Packet::SSH_FXP_LSTAT.new({}).encode(lstat_packet)
          }

          context "when request is valid" do
            let(:request_id){ 1 }
            let(:path){ File.expand_path(".") }
            let(:attrs){
              stat = File.lstat(path)
              attrs = Hash.new
              attrs[:"size"]        = stat.size       if stat.size
              attrs[:"uid"]         = stat.uid        if stat.uid && stat.uid
              attrs[:"gid"]         = stat.gid        if stat.uid && stat.gid
              attrs[:"permissions"] = stat.mode       if stat.mode
              attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
              attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
              attrs
            }

            it "returns attrs response" do
              io.remote.in.write ([lstat_payload.bytesize].pack("N") + lstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_ATTRS::TYPE
              packet = version_class::Packet::SSH_FXP_ATTRS.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq request_id
              expect( packet[:"attrs"]       ).to eq attrs
            end
          end

          context "when request path does not exist" do
            let(:request_id){ 1 }
            let(:path){ "does/not/exist" }

            it "returns status response" do
              io.remote.in.write ([lstat_payload.bytesize].pack("N") + lstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
              if version >= 3
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path is not accessible" do
            let(:request_id){ 1 }
            let(:path){ "dir000/file" }

            before :example do
              Dir.mkdir(File.dirname(path))
              FileUtils.touch(path)
              FileUtils.chmod(0000, File.dirname(path))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(path))
              FileUtils.remove_entry_secure(File.dirname(path))
            end

            it "returns status response" do
              io.remote.in.write ([lstat_payload.bytesize].pack("N") + lstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:request_id){ 1 }
            let(:path){ ("a".."z").to_a.join * 10 }

            it "returns status response" do
              io.remote.in.write ([lstat_payload.bytesize].pack("N") + lstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to fstat request" do
          context "when request is valid" do
            let(:open_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_OPEN::TYPE,
                :"request-id" => open_request_id,
                :"filename"   => filename,
                :"pflags"     => pflags,
                :"attrs"      => open_attrs,
              }
            }
            let(:open_payload){
              version_class::Packet::SSH_FXP_OPEN.new({}).encode(open_packet)
            }
            let(:open_request_id){ 1 }
            let(:filename){ "filename" }
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }
            let(:open_attrs){ {} }
            let(:content){ "0123456789" }

            let(:close_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_CLOSE::TYPE,
                :"request-id" => close_request_id,
                :"handle"     => @handle,
              }
            }
            let(:close_payload){
              version_class::Packet::SSH_FXP_CLOSE.new({}).encode(close_packet)
            }
            let(:close_request_id){ 20 }

            let(:fstat_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_FSTAT::TYPE,
                :"request-id" => fstat_request_id,
                :"handle"     => @handle,
              }
            }
            let(:fstat_payload){
              version_class::Packet::SSH_FXP_FSTAT.new({}).encode(fstat_packet)
            }
            let(:fstat_request_id){ 10 }

            let(:fstat_attrs){
              stat = File.stat(filename)
              attrs = Hash.new
              attrs[:"size"]        = stat.size       if stat.size
              attrs[:"uid"]         = stat.uid        if stat.uid && stat.uid
              attrs[:"gid"]         = stat.gid        if stat.uid && stat.gid
              attrs[:"permissions"] = stat.mode       if stat.mode
              attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
              attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
              attrs
            }

            before :example do
              File.open(filename, "w"){ |f| f.write content }
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              io.remote.in.write ([close_payload.bytesize].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              FileUtils.remove_entry_secure filename
            end

            it "returns attrs response" do
              io.remote.in.write ([fstat_payload.bytesize].pack("N") + fstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_ATTRS::TYPE
              packet = version_class::Packet::SSH_FXP_ATTRS.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq fstat_request_id
              expect( packet[:"attrs"]       ).to eq fstat_attrs
            end
          end

          context "when specified handle does not exist" do
            let(:fstat_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_FSTAT::TYPE,
                :"request-id" => fstat_request_id,
                :"handle"     => handle,
              }
            }
            let(:fstat_payload){
              version_class::Packet::SSH_FXP_FSTAT.new({}).encode(fstat_packet)
            }
            let(:fstat_request_id){ 10 }
            let(:handle){ "handle" }

            it "returns status response" do
              io.remote.in.write ([fstat_payload.bytesize].pack("N") + fstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq fstat_request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "Specified handle does not exist"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to setstat request" do
          let(:setstat_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_SETSTAT::TYPE,
              :"request-id" => request_id,
              :"path"       => path,
              :"attrs"      => newattrs,
            }
          }
          let(:setstat_payload){
            version_class::Packet::SSH_FXP_SETSTAT.new({}).encode(setstat_packet)
          }

          context "when request is valid" do
            let(:request_id){ 1 }
            let(:path){ "target" }

            before :example do
              FileUtils.touch(path)
            end

            after :example do
              FileUtils.remove_entry_secure(path)
            end

            context "when attrs does not have uid and gid" do
              let(:oldattrs){
                stat = File.stat(path)
                attrs = Hash.new
                attrs[:"size"]        = stat.size       if stat.size
                attrs[:"permissions"] = stat.mode       if stat.mode
                attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
                attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
                attrs
              }
              let(:newattrs){
                attrs = Hash.new
                attrs[:"size"]        =     100 if oldattrs.has_key?(:"size")
                attrs[:"permissions"] = 0100000 if oldattrs.has_key?(:"permissions")
                attrs[:"atime"]       =       0 if oldattrs.has_key?(:"atime")
                attrs[:"mtime"]       =       0 if oldattrs.has_key?(:"mtime")
                attrs
              }

              it "returns status response" do
                io.remote.in.write ([setstat_payload.bytesize].pack("N") + setstat_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                expect( packet[:"request-id"] ).to eq request_id
                expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
                if version >= 3
                  expect( packet[:"error message"] ).to eq "Success"
                  expect( packet[:"language tag"]  ).to eq ""
                end
                expect( File.stat(path).size       ).to eq newattrs[:"size"]        if newattrs.has_key?(:"size")
                expect( File.stat(path).mode       ).to eq newattrs[:"permissions"] if newattrs.has_key?(:"permissions")
                expect( File.stat(path).atime.to_i ).to eq newattrs[:"atime"]       if newattrs.has_key?(:"atime")
                expect( File.stat(path).mtime.to_i ).to eq newattrs[:"mtime"]       if newattrs.has_key?(:"mtime")
              end
            end

            context "when attrs has uid and gid" do
              let(:oldattrs){
                stat = File.stat(path)
                attrs = Hash.new
                attrs[:"size"]        = stat.size       if stat.size
                attrs[:"uid"]         = stat.uid        if stat.uid
                attrs[:"gid"]         = stat.gid        if stat.gid
                attrs[:"permissions"] = stat.mode       if stat.mode
                attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
                attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
                attrs
              }
              let(:newattrs){
                attrs = Hash.new
                attrs[:"size"]        =     100 if oldattrs.has_key?(:"size")
                attrs[:"uid"]         =       0 if oldattrs.has_key?(:"uid")
                attrs[:"gid"]         =       0 if oldattrs.has_key?(:"gid")
                attrs[:"permissions"] = 0100000 if oldattrs.has_key?(:"permissions")
                attrs[:"atime"]       =       0 if oldattrs.has_key?(:"atime")
                attrs[:"mtime"]       =       0 if oldattrs.has_key?(:"mtime")
                attrs
              }

              it "returns status response" do
                io.remote.in.write ([setstat_payload.bytesize].pack("N") + setstat_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                expect( packet[:"request-id"] ).to eq request_id
                expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
                if version >= 3
                  expect( packet[:"error message"] ).to eq "Permission denied"
                  expect( packet[:"language tag"]  ).to eq ""
                end
                expect( File.stat(path).size       ).to eq newattrs[:"size"]        if newattrs.has_key?(:"size")
                expect( File.stat(path).mode       ).to eq newattrs[:"permissions"] if newattrs.has_key?(:"permissions")
                expect( File.stat(path).atime.to_i ).to eq newattrs[:"atime"]       if newattrs.has_key?(:"atime")
                expect( File.stat(path).mtime.to_i ).to eq newattrs[:"mtime"]       if newattrs.has_key?(:"mtime")
                expect( File.stat(path).uid        ).to eq oldattrs[:"uid"]         if oldattrs.has_key?(:"uid")
                expect( File.stat(path).gid        ).to eq oldattrs[:"gid"]         if oldattrs.has_key?(:"gid")
              end
            end
          end

          context "when request path does not exist" do
            let(:request_id){ 1 }
            let(:path){ "does/not/exist" }
            let(:newattrs){
              attrs = Hash.new
              attrs[:"permissions"] = 0100000
              attrs[:"atime"]       =       0
              attrs[:"mtime"]       =       0
              attrs
            }

            it "returns status response" do
              io.remote.in.write ([setstat_payload.bytesize].pack("N") + setstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
              if version >= 3
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path is not accessible" do
            let(:request_id){ 1 }
            let(:path){ "dir000/file" }
            let(:newattrs){
              attrs = Hash.new
              attrs[:"permissions"] = 0100000
              attrs[:"atime"]       =       0
              attrs[:"mtime"]       =       0
              attrs
            }

            before :example do
              Dir.mkdir(File.dirname(path))
              FileUtils.touch(path)
              FileUtils.chmod(0000, File.dirname(path))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(path))
              FileUtils.remove_entry_secure(File.dirname(path))
            end

            it "returns status response" do
              io.remote.in.write ([setstat_payload.bytesize].pack("N") + setstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:request_id){ 1 }
            let(:path){ ("a".."z").to_a.join * 10 }
            let(:newattrs){
              attrs = Hash.new
              attrs[:"permissions"] = 0100000
              attrs[:"atime"]       =       0
              attrs[:"mtime"]       =       0
              attrs
            }

            it "returns status response" do
              io.remote.in.write ([setstat_payload.bytesize].pack("N") + setstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to fsetstat request" do
          context "when request is valid" do
            let(:open_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_OPEN::TYPE,
                :"request-id" => open_request_id,
                :"filename"   => filename,
                :"pflags"     => pflags,
                :"attrs"      => open_attrs,
              }
            }
            let(:open_payload){
              version_class::Packet::SSH_FXP_OPEN.new({}).encode(open_packet)
            }
            let(:open_request_id){ 1 }
            let(:filename){ "filename" }
            let(:open_attrs){ {} }
            let(:content){ "0123456789" }

            let(:close_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_CLOSE::TYPE,
                :"request-id" => close_request_id,
                :"handle"     => @handle,
              }
            }
            let(:close_payload){
              version_class::Packet::SSH_FXP_CLOSE.new({}).encode(close_packet)
            }
            let(:close_request_id){ 20 }

            let(:fsetstat_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_FSETSTAT::TYPE,
                :"request-id" => fsetstat_request_id,
                :"handle"     => @handle,
                :"attrs"      => newattrs,
              }
            }
            let(:fsetstat_payload){
              version_class::Packet::SSH_FXP_FSETSTAT.new({}).encode(fsetstat_packet)
            }
            let(:fsetstat_request_id){ 10 }

            before :example do
              File.open(filename, "w"){ |f| f.write content }
              io.remote.in.write ([open_payload.bytesize].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              io.remote.in.write ([close_payload.bytesize].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              FileUtils.remove_entry_secure filename
            end

            context "when attrs does not have size, uid and gid" do
              let(:oldattrs){
                stat = File.stat(filename)
                attrs = Hash.new
                attrs[:"permissions"] = stat.mode       if stat.mode
                attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
                attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
                attrs
              }
              let(:newattrs){
                attrs = Hash.new
                attrs[:"permissions"] = 0100000 if oldattrs.has_key?(:"permissions")
                attrs[:"atime"]       =       0 if oldattrs.has_key?(:"atime")
                attrs[:"mtime"]       =       0 if oldattrs.has_key?(:"mtime")
                attrs
              }

              context "when file is opened for write" do
                let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE }

                it "returns status response" do
                  io.remote.in.write ([fsetstat_payload.bytesize].pack("N") + fsetstat_payload)
                  payload_length = io.remote.out.read(4).unpack("N")[0]
                  payload = io.remote.out.read(payload_length)
                  expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                  packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                  expect( packet[:"request-id"]  ).to eq fsetstat_request_id
                  expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
                  if version >= 3
                    expect( packet[:"error message"] ).to eq "Success"
                    expect( packet[:"language tag"]  ).to eq ""
                  end
                  expect( File.stat(filename).mode       ).to eq newattrs[:"permissions"] if newattrs.has_key?(:"permissions")
                  expect( File.stat(filename).atime.to_i ).to eq newattrs[:"atime"]       if newattrs.has_key?(:"atime")
                  expect( File.stat(filename).mtime.to_i ).to eq newattrs[:"mtime"]       if newattrs.has_key?(:"mtime")
                end
              end

              context "when file is opened for read" do
                let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }

                it "returns status response" do
                  io.remote.in.write ([fsetstat_payload.bytesize].pack("N") + fsetstat_payload)
                  payload_length = io.remote.out.read(4).unpack("N")[0]
                  payload = io.remote.out.read(payload_length)
                  expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                  packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                  expect( packet[:"request-id"]  ).to eq fsetstat_request_id
                  expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
                  if version >= 3
                    expect( packet[:"error message"] ).to eq "Success"
                    expect( packet[:"language tag"]  ).to eq ""
                  end
                  expect( File.stat(filename).mode       ).to eq newattrs[:"permissions"] if newattrs.has_key?(:"permissions")
                  expect( File.stat(filename).atime.to_i ).to eq newattrs[:"atime"]       if newattrs.has_key?(:"atime")
                  expect( File.stat(filename).mtime.to_i ).to eq newattrs[:"mtime"]       if newattrs.has_key?(:"mtime")
                end
              end
            end

            context "when attrs has size and does not have uid and gid" do
              let(:oldattrs){
                stat = File.stat(filename)
                attrs = Hash.new
                attrs[:"size"]        = stat.size       if stat.size
                attrs[:"permissions"] = stat.mode       if stat.mode
                attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
                attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
                attrs
              }
              let(:newattrs){
                attrs = Hash.new
                attrs[:"size"]        =     100 if oldattrs.has_key?(:"size")
                attrs[:"permissions"] = 0100000 if oldattrs.has_key?(:"permissions")
                attrs[:"atime"]       =       0 if oldattrs.has_key?(:"atime")
                attrs[:"mtime"]       =       0 if oldattrs.has_key?(:"mtime")
                attrs
              }

              context "when file is opened for write" do
                let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE }

                it "returns status response" do
                  io.remote.in.write ([fsetstat_payload.bytesize].pack("N") + fsetstat_payload)
                  payload_length = io.remote.out.read(4).unpack("N")[0]
                  payload = io.remote.out.read(payload_length)
                  expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                  packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                  expect( packet[:"request-id"]  ).to eq fsetstat_request_id
                  expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
                  if version >= 3
                    expect( packet[:"error message"] ).to eq "Success"
                    expect( packet[:"language tag"]  ).to eq ""
                  end
                  expect( File.stat(filename).size       ).to eq newattrs[:"size"]        if newattrs.has_key?(:"size")
                  expect( File.stat(filename).mode       ).to eq newattrs[:"permissions"] if newattrs.has_key?(:"permissions")
                  expect( File.stat(filename).atime.to_i ).to eq newattrs[:"atime"]       if newattrs.has_key?(:"atime")
                  expect( File.stat(filename).mtime.to_i ).to eq newattrs[:"mtime"]       if newattrs.has_key?(:"mtime")
                end
              end

              context "when file is opened for read" do
                let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }

                it "returns status response" do
                  io.remote.in.write ([fsetstat_payload.bytesize].pack("N") + fsetstat_payload)
                  payload_length = io.remote.out.read(4).unpack("N")[0]
                  payload = io.remote.out.read(payload_length)
                  expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                  packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                  expect( packet[:"request-id"]  ).to eq fsetstat_request_id
                  expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
                  if version >= 3
                    expect( packet[:"error message"] ).to eq "not opened for writing"
                    expect( packet[:"language tag"]  ).to eq ""
                  end
                  expect( File.stat(filename).size       ).to eq oldattrs[:"size"]        if oldattrs.has_key?(:"size")
                  expect( File.stat(filename).mode       ).to eq oldattrs[:"permissions"] if oldattrs.has_key?(:"permissions")
                  expect( File.stat(filename).atime.to_i ).to eq oldattrs[:"atime"]       if oldattrs.has_key?(:"atime")
                  expect( File.stat(filename).mtime.to_i ).to eq oldattrs[:"mtime"]       if oldattrs.has_key?(:"mtime")
                end
              end
            end

            context "when attrs has size, uid and gid" do
              let(:oldattrs){
                stat = File.stat(filename)
                attrs = Hash.new
                attrs[:"size"]        = stat.size       if stat.size
                attrs[:"uid"]         = stat.uid        if stat.uid
                attrs[:"gid"]         = stat.gid        if stat.gid
                attrs[:"permissions"] = stat.mode       if stat.mode
                attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
                attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
                attrs
              }
              let(:newattrs){
                attrs = Hash.new
                attrs[:"size"]        =     100 if oldattrs.has_key?(:"size")
                attrs[:"uid"]         =       0 if oldattrs.has_key?(:"uid")
                attrs[:"gid"]         =       0 if oldattrs.has_key?(:"gid")
                attrs[:"permissions"] = 0100000 if oldattrs.has_key?(:"permissions")
                attrs[:"atime"]       =       0 if oldattrs.has_key?(:"atime")
                attrs[:"mtime"]       =       0 if oldattrs.has_key?(:"mtime")
                attrs
              }

              context "when file is opened for write" do
                let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE }

                it "returns status response" do
                  io.remote.in.write ([fsetstat_payload.bytesize].pack("N") + fsetstat_payload)
                  payload_length = io.remote.out.read(4).unpack("N")[0]
                  payload = io.remote.out.read(payload_length)
                  expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                  packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                  expect( packet[:"request-id"]  ).to eq fsetstat_request_id
                  expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
                  if version >= 3
                    expect( packet[:"error message"] ).to eq "Permission denied"
                    expect( packet[:"language tag"]  ).to eq ""
                  end
                  expect( File.stat(filename).size       ).to eq newattrs[:"size"]        if newattrs.has_key?(:"size")
                  expect( File.stat(filename).mode       ).to eq newattrs[:"permissions"] if newattrs.has_key?(:"permissions")
                  expect( File.stat(filename).atime.to_i ).to eq newattrs[:"atime"]       if newattrs.has_key?(:"atime")
                  expect( File.stat(filename).mtime.to_i ).to eq newattrs[:"mtime"]       if newattrs.has_key?(:"mtime")
                  expect( File.stat(filename).uid        ).to eq oldattrs[:"uid"]         if oldattrs.has_key?(:"uid")
                  expect( File.stat(filename).gid        ).to eq oldattrs[:"gid"]         if oldattrs.has_key?(:"gid")
                end
              end

              context "when file is opened for read" do
                let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ }

                it "returns status response" do
                  io.remote.in.write ([fsetstat_payload.bytesize].pack("N") + fsetstat_payload)
                  payload_length = io.remote.out.read(4).unpack("N")[0]
                  payload = io.remote.out.read(payload_length)
                  expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                  packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                  expect( packet[:"request-id"]  ).to eq fsetstat_request_id
                  expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
                  if version >= 3
                    expect( packet[:"error message"] ).to eq "not opened for writing"
                    expect( packet[:"language tag"]  ).to eq ""
                  end
                  expect( File.stat(filename).size       ).to eq oldattrs[:"size"]        if oldattrs.has_key?(:"size")
                  expect( File.stat(filename).mode       ).to eq oldattrs[:"permissions"] if oldattrs.has_key?(:"permissions")
                  expect( File.stat(filename).atime.to_i ).to eq oldattrs[:"atime"]       if oldattrs.has_key?(:"atime")
                  expect( File.stat(filename).mtime.to_i ).to eq oldattrs[:"mtime"]       if oldattrs.has_key?(:"mtime")
                  expect( File.stat(filename).uid        ).to eq oldattrs[:"uid"]         if oldattrs.has_key?(:"uid")
                  expect( File.stat(filename).gid        ).to eq oldattrs[:"gid"]         if oldattrs.has_key?(:"gid")
                end
              end
            end
          end

          context "when specified handle does not exist" do
            let(:fsetstat_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_FSTAT::TYPE,
                :"request-id" => fsetstat_request_id,
                :"handle"     => handle,
                :"attrs"      => newattrs,
              }
            }
            let(:fsetstat_payload){
              version_class::Packet::SSH_FXP_FSTAT.new({}).encode(fsetstat_packet)
            }
            let(:fsetstat_request_id){ 10 }
            let(:handle){ "handle" }
            let(:newattrs){
              attrs = Hash.new
              attrs[:"permissions"] = 0100000
              attrs[:"atime"]       =       0
              attrs[:"mtime"]       =       0
              attrs
            }

            it "returns status response" do
              io.remote.in.write ([fsetstat_payload.bytesize].pack("N") + fsetstat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq fsetstat_request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "Specified handle does not exist"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to opendir request" do
          let(:opendir_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_OPENDIR::TYPE,
              :"request-id" => request_id,
              :"path"       => path,
            }
          }
          let(:opendir_payload){
            version_class::Packet::SSH_FXP_OPENDIR.new({}).encode(opendir_packet)
          }
          let(:request_id){ 1 }

          context "when request is valid" do
            let(:path){ "path" }
            let(:handle){ "handle" }

            it "returns handle response" do
              expect(::Dir).to receive(:open).with(path).and_return(handle)
              io.remote.in.write ([opendir_payload.bytesize].pack("N") + opendir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"handle"]     ).to eq handle.object_id.to_s(16)
            end
          end

          context "when the path does not exist" do
            let(:path){ "does/not/exist" }

            it "returns status response" do
              io.remote.in.write ([opendir_payload.bytesize].pack("N") + opendir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
              if version >= 3
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when the path is not accessible" do
            let(:path){ "dir000/dir" }

            before :example do
              Dir.mkdir(File.dirname(path))
              Dir.mkdir(path)
              FileUtils.chmod(0000, File.dirname(path))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(path))
              FileUtils.remove_entry_secure(File.dirname(path))
            end

            it "returns status response" do
              io.remote.in.write ([opendir_payload.bytesize].pack("N") + opendir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when the path is not a directory" do
            let(:path){ "path" }
            let(:handle){ "handle" }

            before :example do
              FileUtils.touch(path)
            end

            after :example do
              FileUtils.remove_entry_secure(path)
            end

            it "returns status response" do
              io.remote.in.write ([opendir_payload.bytesize].pack("N") + opendir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "Not a directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:path){ ("a".."z").to_a.join * 10 }

            it "returns status response" do
              io.remote.in.write ([opendir_payload.bytesize].pack("N") + opendir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to readdir request" do
          context "when request is valid" do
            let(:opendir_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_OPENDIR::TYPE,
                :"request-id" => opendir_request_id,
                :"path"       => path,
              }
            }
            let(:opendir_payload){
              version_class::Packet::SSH_FXP_OPENDIR.new({}).encode(opendir_packet)
            }
            let(:opendir_request_id){ 1 }
            let(:path){ "dirX" }
            let(:file){ "file" }
            let(:symlink){ "symlink" }

            let(:close_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_CLOSE::TYPE,
                :"request-id" => close_request_id,
                :"handle"     => @handle,
              }
            }
            let(:close_payload){
              version_class::Packet::SSH_FXP_CLOSE.new({}).encode(close_packet)
            }
            let(:close_request_id){ 20 }

            let(:readdir_packet_0){
              {
                :"type"       => version_class::Packet::SSH_FXP_READDIR::TYPE,
                :"request-id" => readdir_request_id_0,
                :"handle"     => @handle,
              }
            }
            let(:readdir_payload_0){
              version_class::Packet::SSH_FXP_READDIR.new({}).encode(readdir_packet_0)
            }
            let(:readdir_request_id_0){ 10 }

            let(:readdir_packet_1){
              {
                :"type"       => version_class::Packet::SSH_FXP_READDIR::TYPE,
                :"request-id" => readdir_request_id_1,
                :"handle"     => @handle,
              }
            }
            let(:readdir_payload_1){
              version_class::Packet::SSH_FXP_READDIR.new({}).encode(readdir_packet_1)
            }
            let(:readdir_request_id_1){ 11 }

            let(:path_attrs){
              stat = File.lstat(path)
              attrs = Hash.new
              attrs[:"size"]        = stat.size       if stat.size
              attrs[:"uid"]         = stat.uid        if stat.uid && stat.uid
              attrs[:"gid"]         = stat.gid        if stat.uid && stat.gid
              attrs[:"permissions"] = stat.mode       if stat.mode
              attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
              attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
              attrs
            }
            let(:file_attrs){
              stat = File.lstat(File.join(path, file))
              attrs = Hash.new
              attrs[:"size"]        = stat.size       if stat.size
              attrs[:"uid"]         = stat.uid        if stat.uid && stat.uid
              attrs[:"gid"]         = stat.gid        if stat.uid && stat.gid
              attrs[:"permissions"] = stat.mode       if stat.mode
              attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
              attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
              attrs
            }
            let(:symlink_attrs){
              stat = File.lstat(File.join(path, symlink))
              attrs = Hash.new
              attrs[:"size"]        = stat.size       if stat.size
              attrs[:"uid"]         = stat.uid        if stat.uid && stat.uid
              attrs[:"gid"]         = stat.gid        if stat.uid && stat.gid
              attrs[:"permissions"] = stat.mode       if stat.mode
              attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
              attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
              attrs
            }
            let(:parent_attrs){
              stat = File.lstat(File.join(path, ".."))
              attrs = Hash.new
              attrs[:"size"]        = stat.size       if stat.size
              attrs[:"uid"]         = stat.uid        if stat.uid && stat.uid
              attrs[:"gid"]         = stat.gid        if stat.uid && stat.gid
              attrs[:"permissions"] = stat.mode       if stat.mode
              attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
              attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
              attrs
            }

            before :example do
              Dir.mkdir(path)
              FileUtils.touch(File.join(path, file))
              File.symlink(File.join(path, file), File.join(path, symlink))
              File.chmod(0700, path)
              File.chmod(0600, File.join(path, file))
              File.utime(0, 0, path)
              time = Time.new(Time.now.year, 1, 2, 3, 4, nil, Time.now.utc_offset)
              File.utime(time, time, File.join(path, file))
              io.remote.in.write ([opendir_payload.bytesize].pack("N") + opendir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              io.remote.in.write ([close_payload.bytesize].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              FileUtils.remove_entry_secure path
            end

            it "returns name and then EOF status response" do
              io.remote.in.write ([readdir_payload_0.bytesize].pack("N") + readdir_payload_0)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_NAME::TYPE
              packet = version_class::Packet::SSH_FXP_NAME.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq readdir_request_id_0
              expect( packet[:"count"]       ).to eq 4
              list = {
                packet[:"filename[0]"] => {:"longname" => packet[:"longname[0]"], :"attrs" => packet[:"attrs[0]"]},
                packet[:"filename[1]"] => {:"longname" => packet[:"longname[1]"], :"attrs" => packet[:"attrs[1]"]},
                packet[:"filename[2]"] => {:"longname" => packet[:"longname[2]"], :"attrs" => packet[:"attrs[2]"]},
                packet[:"filename[3]"] => {:"longname" => packet[:"longname[3]"], :"attrs" => packet[:"attrs[3]"]},
              }
              expect( list.keys ).to match_array [".", "..", file, symlink]
              expect( list["."][:"longname"]     ).to match /drwx------ ... ........ ........ ........ Jan  1  1970 \./
              expect( list["."][:"attrs"]        ).to eq path_attrs
              expect( list[".."][:"longname"]    ).to match /.......... ... ........ ........ ........ ... .. ..... \.\./
              expect( list[".."][:"attrs"]       ).to eq parent_attrs
              expect( list[file][:"longname"]    ).to match /-rw-------   1 ........ ........        0 Jan  2 03:04 #{file}/
              expect( list[file][:"attrs"]       ).to eq file_attrs
              expect( list[symlink][:"longname"] ).to match /l.........   1 ........ ........ ........ ... .. ..... #{symlink}/
              expect( list[symlink][:"attrs"]    ).to eq symlink_attrs

              io.remote.in.write ([readdir_payload_1.bytesize].pack("N") + readdir_payload_1)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq readdir_request_id_1
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_EOF
              if version >= 3
                expect( packet[:"error message"] ).to eq "End of file"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when specified handle does not exist" do
            let(:readdir_packet){
              {
                :"type"       => version_class::Packet::SSH_FXP_READDIR::TYPE,
                :"request-id" => readdir_request_id,
                :"handle"     => handle,
              }
            }
            let(:readdir_payload){
              version_class::Packet::SSH_FXP_READDIR.new({}).encode(readdir_packet)
            }
            let(:readdir_request_id){ 10 }
            let(:handle){ "handle" }

            it "returns status response" do
              io.remote.in.write ([readdir_payload.bytesize].pack("N") + readdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq readdir_request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "Specified handle does not exist"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to remove request" do
          let(:remove_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_REMOVE::TYPE,
              :"request-id" => request_id,
              :"filename"   => filename,
            }
          }
          let(:remove_payload){
            version_class::Packet::SSH_FXP_REMOVE.new({}).encode(remove_packet)
          }

          context "when request is valid" do
            let(:request_id){ 1 }
            let(:filename){ "dir000/file" }

            before :example do
              Dir.mkdir(File.dirname(filename))
              FileUtils.touch(filename)
            end

            after :example do
              FileUtils.remove_entry_secure(File.dirname(filename))
            end

            it "returns status response" do
              io.remote.in.write ([remove_payload.bytesize].pack("N") + remove_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end
              expect( File.exist? filename ).to be false
            end
          end

          context "when request filename does not exist" do
            let(:request_id){ 1 }
            let(:filename){ "does/not/exist" }

            it "returns status response" do
              io.remote.in.write ([remove_payload.bytesize].pack("N") + remove_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
              if version >= 3
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request filename is not accessible" do
            let(:request_id){ 1 }
            let(:filename){ "dir000/file" }

            before :example do
              Dir.mkdir(File.dirname(filename))
              FileUtils.touch(filename)
              FileUtils.chmod(0000, File.dirname(filename))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(filename))
              FileUtils.remove_entry_secure(File.dirname(filename))
            end

            it "returns status response" do
              io.remote.in.write ([remove_payload.bytesize].pack("N") + remove_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request filename causes other error" do
            let(:request_id){ 1 }
            let(:filename){ ("a".."z").to_a.join * 10 }

            it "returns status response" do
              io.remote.in.write ([remove_payload.bytesize].pack("N") + remove_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to mkdir request" do
          let(:mkdir_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_MKDIR::TYPE,
              :"request-id" => request_id,
              :"path"       => path,
              :"attrs"      => attrs, # >= version 3
            }
          }
          let(:mkdir_payload){
            version_class::Packet::SSH_FXP_MKDIR.new({}).encode(mkdir_packet)
          }
          let(:request_id){ 1 }
          let(:attrs){ {:"permissions" => 040700} }

          context "when request is valid" do
            let(:path){ "newdir" }

            after :example do
              FileUtils.remove_entry_secure(path)
            end

            it "returns status response" do
              io.remote.in.write ([mkdir_payload.bytesize].pack("N") + mkdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end
              expect( Dir.exist?(path) ).to be true
              if version >= 3
                expect( File.stat(path).mode ).to eq attrs[:"permissions"]
              end
            end
          end

          context "when the path is not accessible" do
            let(:path){ "dir000/dir" }

            before :example do
              Dir.mkdir(File.dirname(path))
              FileUtils.chmod(0000, File.dirname(path))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(path))
              FileUtils.remove_entry_secure(File.dirname(path))
            end

            it "returns status response" do
              io.remote.in.write ([mkdir_payload.bytesize].pack("N") + mkdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when the path already exists" do
            let(:path){ "newdir" }

            before :example do
              Dir.mkdir path
            end

            after :example do
              FileUtils.remove_entry_secure(path)
            end

            it "returns status response" do
              io.remote.in.write ([mkdir_payload.bytesize].pack("N") + mkdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "File exists"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:path){ ("a".."z").to_a.join * 10 }

            it "returns status response" do
              io.remote.in.write ([mkdir_payload.bytesize].pack("N") + mkdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to rmdir request" do
          let(:rmdir_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_RMDIR::TYPE,
              :"request-id" => request_id,
              :"path"       => path,
            }
          }
          let(:rmdir_payload){
            version_class::Packet::SSH_FXP_RMDIR.new({}).encode(rmdir_packet)
          }
          let(:request_id){ 1 }

          context "when request is valid" do
            let(:path){ "newdir" }

            before :example do
              Dir.mkdir(path)
            end

            it "returns status response" do
              io.remote.in.write ([rmdir_payload.bytesize].pack("N") + rmdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end
              expect( File.exist? path ).to be false
            end
          end

          context "when the path does not exist" do
            let(:path){ "does/not/exist" }

            it "returns status response" do
              io.remote.in.write ([rmdir_payload.bytesize].pack("N") + rmdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
              if version >= 3
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when the path is not accessible" do
            let(:path){ "dir000/dir" }

            before :example do
              Dir.mkdir(File.dirname(path))
              Dir.mkdir(path)
              FileUtils.chmod(0000, File.dirname(path))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(path))
              FileUtils.remove_entry_secure(File.dirname(path))
            end

            it "returns status response" do
              io.remote.in.write ([rmdir_payload.bytesize].pack("N") + rmdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when the path is not a directory" do
            let(:path){ "file" }

            before :example do
              FileUtils.touch(path)
            end

            after :example do
              FileUtils.remove_entry_secure(path)
            end

            it "returns status response" do
              io.remote.in.write ([rmdir_payload.bytesize].pack("N") + rmdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "Not a directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when the path is not empty" do
            let(:path){ "dirX" }

            before :example do
              Dir.mkdir(path)
              FileUtils.touch(File.join(path, "file"))
            end

            after :example do
              FileUtils.remove_entry_secure(path)
            end

            it "returns status response" do
              io.remote.in.write ([rmdir_payload.bytesize].pack("N") + rmdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "Directory not empty"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:path){ ("a".."z").to_a.join * 10 }

            it "returns status response" do
              io.remote.in.write ([rmdir_payload.bytesize].pack("N") + rmdir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to realpath request" do
          let(:realpath_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_REALPATH::TYPE,
              :"request-id" => request_id,
              :"path"       => path,
            }
          }
          let(:realpath_payload){
            version_class::Packet::SSH_FXP_REALPATH.new({}).encode(realpath_packet)
          }

          context "when request is valid" do
            let(:request_id){ 1 }
            let(:path){ "." }

            it "returns name response" do
              io.remote.in.write ([realpath_payload.bytesize].pack("N") + realpath_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_NAME::TYPE
              packet = version_class::Packet::SSH_FXP_NAME.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq request_id
              expect( packet[:"count"]       ).to eq 1
              expect( packet[:"filename[0]"] ).to eq File.absolute_path(path)
              expect( packet[:"longname[0]"] ).to eq File.absolute_path(path)
              expect( packet[:"attrs[0]"]    ).to eq ({})
            end
          end
        end

        context "when responding to stat request" do
          let(:stat_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_STAT::TYPE,
              :"request-id" => request_id,
              :"path"       => path,
            }
          }
          let(:stat_payload){
            version_class::Packet::SSH_FXP_STAT.new({}).encode(stat_packet)
          }

          context "when request is valid" do
            let(:request_id){ 1 }
            let(:path){ File.expand_path(".") }
            let(:attrs){
              stat = File.stat(path)
              attrs = Hash.new
              attrs[:"size"]        = stat.size       if stat.size
              attrs[:"uid"]         = stat.uid        if stat.uid && stat.uid
              attrs[:"gid"]         = stat.gid        if stat.uid && stat.gid
              attrs[:"permissions"] = stat.mode       if stat.mode
              attrs[:"atime"]       = stat.atime.to_i if stat.atime && stat.mtime
              attrs[:"mtime"]       = stat.mtime.to_i if stat.atime && stat.mtime
              attrs
            }

            it "returns attrs response" do
              io.remote.in.write ([stat_payload.bytesize].pack("N") + stat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_ATTRS::TYPE
              packet = version_class::Packet::SSH_FXP_ATTRS.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq request_id
              expect( packet[:"attrs"]       ).to eq attrs
            end
          end

          context "when request path does not exist" do
            let(:request_id){ 1 }
            let(:path){ "does/not/exist" }

            it "returns status response" do
              io.remote.in.write ([stat_payload.bytesize].pack("N") + stat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
              if version >= 3
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path is not accessible" do
            let(:request_id){ 1 }
            let(:path){ "dir000/file" }

            before :example do
              Dir.mkdir(File.dirname(path))
              FileUtils.touch(path)
              FileUtils.chmod(0000, File.dirname(path))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(path))
              FileUtils.remove_entry_secure(File.dirname(path))
            end

            it "returns status response" do
              io.remote.in.write ([stat_payload.bytesize].pack("N") + stat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:request_id){ 1 }
            let(:path){ ("a".."z").to_a.join * 10 }

            it "returns status response" do
              io.remote.in.write ([stat_payload.bytesize].pack("N") + stat_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        next if version < 2

        context "when responding to rename request" do
          let(:rename_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_RENAME::TYPE,
              :"request-id" => request_id,
              :"oldpath"    => oldpath,
              :"newpath"    => newpath,
            }
          }
          let(:rename_payload){
            version_class::Packet::SSH_FXP_RENAME.new({}).encode(rename_packet)
          }

          context "when request is valid" do
            let(:request_id){ 1 }
            let(:oldpath){ "oldpath" }
            let(:newpath){ "newpath" }

            before :example do
              FileUtils.touch(oldpath)
            end

            after :example do
              FileUtils.remove_entry_secure(newpath)
            end

            it "returns status response" do
              expect( File.exist?(oldpath) ).to be true
              expect( File.exist?(newpath) ).to be false
              io.remote.in.write ([rename_payload.bytesize].pack("N") + rename_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end
              expect( File.exist?(oldpath) ).to be false
              expect( File.exist?(newpath) ).to be true
            end
          end

          context "when request newpath already exists" do
            let(:request_id){ 1 }
            let(:oldpath){ "oldpath" }
            let(:newpath){ "newpath" }

            before :example do
              FileUtils.touch(newpath)
            end

            after :example do
              FileUtils.remove_entry_secure(newpath)
            end

            it "returns status response" do
              io.remote.in.write ([rename_payload.bytesize].pack("N") + rename_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "File exists"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request oldpath does not exist" do
            let(:request_id){ 1 }
            let(:oldpath){ "does/not/exist" }
            let(:newpath){ "newpath" }

            it "returns status response" do
              io.remote.in.write ([rename_payload.bytesize].pack("N") + rename_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
              if version >= 3
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request oldpath is not accessible" do
            let(:request_id){ 1 }
            let(:oldpath){ "dir000/oldpath" }
            let(:newpath){ "newpath" }

            before :example do
              Dir.mkdir(File.dirname(oldpath))
              FileUtils.touch(oldpath)
              FileUtils.chmod(0000, File.dirname(oldpath))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(oldpath))
              FileUtils.remove_entry_secure(File.dirname(oldpath))
            end

            it "returns status response" do
              io.remote.in.write ([rename_payload.bytesize].pack("N") + rename_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:request_id){ 1 }
            let(:oldpath){ "oldpath" }
            let(:newpath){ ("a".."z").to_a.join * 10 }

            before :example do
              FileUtils.touch(oldpath)
            end

            after :example do
              FileUtils.remove_entry_secure(oldpath)
            end

            it "returns status response" do
              io.remote.in.write ([rename_payload.bytesize].pack("N") + rename_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        next if version < 3

        context "when responding to readlink request" do
          let(:readlink_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_READLINK::TYPE,
              :"request-id" => request_id,
              :"path"       => path,
            }
          }
          let(:readlink_payload){
            version_class::Packet::SSH_FXP_READLINK.new({}).encode(readlink_packet)
          }

          context "when request is valid" do
            let(:request_id){ 1 }
            let(:path){ "link" }
            let(:target){ "target" }

            before :example do
              FileUtils.touch(target)
              File.symlink(target, path)
            end

            after :example do
              FileUtils.remove_entry_secure(path)
              FileUtils.remove_entry_secure(target)
            end

            it "returns name response" do
              io.remote.in.write ([readlink_payload.bytesize].pack("N") + readlink_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_NAME::TYPE
              packet = version_class::Packet::SSH_FXP_NAME.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq request_id
              expect( packet[:"count"]       ).to eq 1
              expect( packet[:"filename[0]"] ).to eq File.realpath(target)
              expect( packet[:"longname[0]"] ).to eq File.realpath(target)
              expect( packet[:"attrs[0]"]    ).to eq ({})
            end
          end

          context "when request oldpath does not exist" do
            let(:request_id){ 1 }
            let(:path){ "does/not/exist" }

            it "returns status response" do
              io.remote.in.write ([readlink_payload.bytesize].pack("N") + readlink_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
              if version >= 3
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path is not accessible" do
            let(:request_id){ 1 }
            let(:path){ "dir000/oldfile" }

            before :example do
              Dir.mkdir(File.dirname(path))
              FileUtils.touch(path)
              FileUtils.chmod(0000, File.dirname(path))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(path))
              FileUtils.remove_entry_secure(File.dirname(path))
            end

            it "returns status response" do
              io.remote.in.write ([readlink_payload.bytesize].pack("N") + readlink_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:request_id){ 1 }
            let(:path){ ("a".."z").to_a.join * 10 }

            it "returns status response" do
              io.remote.in.write ([readlink_payload.bytesize].pack("N") + readlink_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to symlink request" do
          let(:symlink_packet){
            {
              :"type"       => version_class::Packet::SSH_FXP_SYMLINK::TYPE,
              :"request-id" => request_id,
              :"targetpath" => targetpath,
              :"linkpath"   => linkpath,
            }
          }
          let(:symlink_payload){
            version_class::Packet::SSH_FXP_SYMLINK.new({}).encode(symlink_packet)
          }

          context "when request is valid" do
            let(:request_id){ 1 }
            let(:targetpath){ "targetpath" }
            let(:linkpath){ "linkpath" }

            after :example do
              FileUtils.remove_entry_secure(linkpath)
            end

            it "returns name response" do
              io.remote.in.write ([symlink_payload.bytesize].pack("N") + symlink_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end
              expect( File.symlink?(linkpath) ).to be true
            end
          end

          context "when request linkpath is not accessible" do
            let(:request_id){ 1 }
            let(:targetpath){ "targetpath" }
            let(:linkpath){ "dir000/linkpath" }

            before :example do
              Dir.mkdir(File.dirname(linkpath))
              FileUtils.chmod(0000, File.dirname(linkpath))
            end

            after :example do
              FileUtils.chmod(0755, File.dirname(linkpath))
              FileUtils.remove_entry_secure(File.dirname(linkpath))
            end

            it "returns status response" do
              io.remote.in.write ([symlink_payload.bytesize].pack("N") + symlink_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
              if version >= 3
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request linkpath already exists" do
            let(:request_id){ 1 }
            let(:targetpath){ "targetpath" }
            let(:linkpath){ "linkpath" }

            before :example do
              FileUtils.touch(linkpath)
            end

            after :example do
              FileUtils.remove_entry_secure(linkpath)
            end

            it "returns status response" do
              io.remote.in.write ([symlink_payload.bytesize].pack("N") + symlink_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to eq "File exists"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "when request path causes other error" do
            let(:request_id){ 1 }
            let(:targetpath){ "targetpath" }
            let(:linkpath){ ("a".."z").to_a.join * 10 }

            it "returns status response" do
              io.remote.in.write ([symlink_payload.bytesize].pack("N") + symlink_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end

        context "when responding to extended request" do
          let(:extended_payload){
            version_class::Packet::SSH_FXP_EXTENDED.new({}).encode(extended_packet)
          }

          context "with unsupported extended-request" do
            let(:extended_packet){
              {
                :"type"             => version_class::Packet::SSH_FXP_EXTENDED::TYPE,
                :"request-id"       => request_id,
                :"extended-request" => extended_request,
              }
            }

            context "when request is valid" do
              let(:request_id){ 1 }
              let(:extended_request){ "unsupported" }

              it "returns status response" do
                io.remote.in.write ([extended_payload.bytesize].pack("N") + extended_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                expect( packet[:"request-id"]    ).to eq request_id
                expect( packet[:"code"]          ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OP_UNSUPPORTED
                expect( packet[:"error message"] ).to eq "Unsupported extended-request: #{extended_request}"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end

          context "with hardlink@openssh.com extended-request" do
            let(:extended_packet){
              {
                :"type"             => version_class::Packet::SSH_FXP_EXTENDED::TYPE,
                :"request-id"       => request_id,
                :"extended-request" => extended_request,
                :"oldpath"          => oldpath,
                :"newpath"          => newpath,
              }
            }
            let(:extended_request){ "hardlink@openssh.com" }

            context "when request is valid" do
              let(:request_id){ 1 }
              let(:oldpath){ "oldpath" }
              let(:newpath){ "newpath" }

              before :example do
                FileUtils.touch(oldpath)
              end

              after :example do
                FileUtils.remove_entry_secure(oldpath)
                FileUtils.remove_entry_secure(newpath)
              end

              it "returns status response" do
                io.remote.in.write ([extended_payload.bytesize].pack("N") + extended_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                expect( packet[:"request-id"]    ).to eq request_id
                expect( packet[:"code"]          ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
                expect( File.stat(newpath).ino   ).to eq File.stat(oldpath).ino
              end
            end

            context "when request oldpath does not exist" do
              let(:request_id){ 1 }
              let(:oldpath){ "oldpath" }
              let(:newpath){ "newpath" }

              it "returns status response" do
                io.remote.in.write ([extended_payload.bytesize].pack("N") + extended_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                expect( packet[:"request-id"] ).to eq request_id
                expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_NO_SUCH_FILE
                expect( packet[:"error message"] ).to eq "No such file or directory"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end

            context "when request oldpath is not accessible" do
              let(:request_id){ 1 }
              let(:oldpath){ "dir000/oldpath" }
              let(:newpath){ "newpath" }

              before :example do
                Dir.mkdir(File.dirname(oldpath))
                FileUtils.chmod(0000, File.dirname(oldpath))
              end

              after :example do
                FileUtils.chmod(0755, File.dirname(oldpath))
                FileUtils.remove_entry_secure(File.dirname(oldpath))
              end

              it "returns status response" do
                io.remote.in.write ([extended_payload.bytesize].pack("N") + extended_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                expect( packet[:"request-id"] ).to eq request_id
                expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end

            context "when request newpath is not accessible" do
              let(:request_id){ 1 }
              let(:oldpath){ "oldpath" }
              let(:newpath){ "dir000/newpath" }

              before :example do
                FileUtils.touch(oldpath)
                Dir.mkdir(File.dirname(newpath))
                FileUtils.chmod(0000, File.dirname(newpath))
              end

              after :example do
                FileUtils.chmod(0755, File.dirname(newpath))
                FileUtils.remove_entry_secure(File.dirname(newpath))
              end

              it "returns status response" do
                io.remote.in.write ([extended_payload.bytesize].pack("N") + extended_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                expect( packet[:"request-id"] ).to eq request_id
                expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_PERMISSION_DENIED
                expect( packet[:"error message"] ).to eq "Permission denied"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end

            context "when request newpath already exists" do
              let(:request_id){ 1 }
              let(:oldpath){ "oldpath" }
              let(:newpath){ "newpath" }

              before :example do
                FileUtils.touch(oldpath)
                FileUtils.touch(newpath)
              end

              after :example do
                FileUtils.remove_entry_secure(oldpath)
                FileUtils.remove_entry_secure(newpath)
              end

              it "returns status response" do
                io.remote.in.write ([extended_payload.bytesize].pack("N") + extended_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                expect( packet[:"request-id"] ).to eq request_id
                expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
                expect( packet[:"error message"] ).to eq "File exists"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end

            context "when request newpath causes other error" do
              let(:request_id){ 1 }
              let(:oldpath){ "oldpath" }
              let(:newpath){ ("a".."z").to_a.join * 10 }

              before :example do
                FileUtils.touch(oldpath)
              end

              after :example do
                FileUtils.remove_entry_secure(oldpath)
              end

              it "returns status response" do
                io.remote.in.write ([extended_payload.bytesize].pack("N") + extended_payload)
                payload_length = io.remote.out.read(4).unpack("N")[0]
                payload = io.remote.out.read(payload_length)
                expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_STATUS::TYPE
                packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
                expect( packet[:"request-id"] ).to eq request_id
                expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
                expect( packet[:"error message"] ).to start_with "File name too long"
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end
      end
    end
  end
end
