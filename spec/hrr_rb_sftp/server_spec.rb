require "fileutils"

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
      expect{ described_class.new }.not_to raise_error
    end
  end

  describe "#start" do
    let(:server){
      described_class.new
    }

    it "takes in, out, err arguments and starts negotiating version then responds to requests" do
      expect( server ).to receive(:negotiate_version).with(no_args).once
      expect( server ).to receive(:respond_to_requests).with(no_args).once
      expect{ server.start *io.local.to_a }.not_to raise_error
    end

    it "raises an error when less than 3 arguments" do
      expect{ server.start "arg1", "arg2" }.to raise_error ArgumentError
    end

    it "raises an error when more than 3 arguments" do
      expect{ server.start "arg1", "arg2", "arg3", "arg4" }.to raise_error ArgumentError
    end
  end

  describe "#negotiate_version" do
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
        server = described_class.new
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
          io.remote.in.write ([init_payload.length].pack("N") + init_payload)
          payload_length = io.remote.out.read(4).unpack("N")[0]
          payload = io.remote.out.read(payload_length)
          expect( payload[0].unpack("C")[0] ).to eq HrrRbSftp::Protocol::Common::Packet::SSH_FXP_VERSION::TYPE
          packet = HrrRbSftp::Protocol::Common::Packet::SSH_FXP_VERSION.new({}).decode(payload)
          expect( packet[:"version"]    ).to eq version
          expect( packet[:"extensions"] ).to eq []
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

    before :example do
      @thread = Thread.new{
        server = described_class.new
        server.start *io.local.to_a
      }
      io.remote.in.write ([init_payload.length].pack("N") + init_payload)
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
            io.remote.in.write ([realpath_payload.length].pack("N") + realpath_payload)
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
            io.remote.in.write ([realpath_payload.length].pack("N") + realpath_payload)
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
            io.remote.in.write ([realpath_payload.length].pack("N") + realpath_payload)
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
              io.remote.in.write ([realpath_payload.length].pack("N") + realpath_payload)
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
              io.remote.in.write ([stat_payload.length].pack("N") + stat_payload)
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
              io.remote.in.write ([stat_payload.length].pack("N") + stat_payload)
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
              io.remote.in.write ([stat_payload.length].pack("N") + stat_payload)
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
              io.remote.in.write ([stat_payload.length].pack("N") + stat_payload)
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
              io.remote.in.write ([lstat_payload.length].pack("N") + lstat_payload)
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
              io.remote.in.write ([lstat_payload.length].pack("N") + lstat_payload)
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
              io.remote.in.write ([lstat_payload.length].pack("N") + lstat_payload)
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
              io.remote.in.write ([lstat_payload.length].pack("N") + lstat_payload)
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
            let(:oldattrs){
              stat = File.stat(path)
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

            before :example do
              FileUtils.touch(path)
            end

            after :example do
              FileUtils.remove_entry_secure(path)
            end

            it "returns attrs response" do
              io.remote.in.write ([setstat_payload.length].pack("N") + setstat_payload)
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
              expect( File.stat(path).mode       ).to eq newattrs[:"permissions"]
              expect( File.stat(path).atime.to_i ).to eq newattrs[:"atime"]
              expect( File.stat(path).mtime.to_i ).to eq newattrs[:"mtime"]
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
              io.remote.in.write ([setstat_payload.length].pack("N") + setstat_payload)
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
              io.remote.in.write ([setstat_payload.length].pack("N") + setstat_payload)
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
              io.remote.in.write ([setstat_payload.length].pack("N") + setstat_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
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
            let(:attrs){ {:"permissions" => permissions} }
            let(:permissions){ 0644 }

            it "returns handle response" do
              expect(::File).to receive(:open).with(filename, ::File::WRONLY, permissions).and_return(handle)
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq request_id
              expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
            end
          end

          context "with SSH_FXF_READ and SSH_FXF_WRITE flags" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_READ | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE }
            let(:attrs){ {} }

            it "returns handle response" do
              expect(::File).to receive(:open).with(filename, ::File::RDWR).and_return(handle)
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq request_id
              expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
            end
          end

          context "with SSH_FXF_WRITE and SSH_FXF_APPEND flags" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_APPEND }
            let(:attrs){ {} }

            it "returns handle response" do
              expect(::File).to receive(:open).with(filename, ::File::WRONLY | ::File::APPEND).and_return(handle)
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq request_id
              expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
            end
          end

          context "with SSH_FXF_WRITE, SSH_FXF_CREAT, SSH_FXF_TRUNC, and SSH_FXF_EXCL flags" do
            let(:pflags){ version_class::Packet::SSH_FXP_OPEN::SSH_FXF_WRITE | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_CREAT | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_TRUNC | version_class::Packet::SSH_FXP_OPEN::SSH_FXF_EXCL }
            let(:attrs){ {:"permissions" => permissions} }
            let(:permissions){ 0644 }

            it "returns handle response" do
              expect(::File).to receive(:open).with(filename, ::File::WRONLY | ::File::CREAT | ::File::TRUNC | ::File::EXCL, permissions).and_return(handle)
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_HANDLE::TYPE
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq request_id
              expect( packet[:"handle"]      ).to eq handle.object_id.to_s(16)
            end
          end

          context "when no flag is specified" do
            let(:pflags){ 0 }
            let(:attrs){ {} }

            it "returns status response" do
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              FileUtils.remove_entry_secure filename
            end

            it "returns status response" do
              io.remote.in.write ([close_payload.length].pack("N") + close_payload)
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
              io.remote.in.write ([close_payload.length].pack("N") + close_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              io.remote.in.write ([close_payload.length].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              FileUtils.remove_entry_secure filename
            end

            it "returns data and then EOF status response" do
              io.remote.in.write ([read_payload_0.length].pack("N") + read_payload_0)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_DATA::TYPE
              packet = version_class::Packet::SSH_FXP_DATA.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq read_request_id_0
              expect( packet[:"data"]       ).to eq content[0,5]

              io.remote.in.write ([read_payload_1.length].pack("N") + read_payload_1)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_DATA::TYPE
              packet = version_class::Packet::SSH_FXP_DATA.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq read_request_id_1
              expect( packet[:"data"]       ).to eq content[5,5]

              io.remote.in.write ([read_payload_2.length].pack("N") + read_payload_2)
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
              io.remote.in.write ([read_payload.length].pack("N") + read_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              FileUtils.remove_entry_secure filename
            end

            it "returns status response" do
              io.remote.in.write ([write_payload_0.length].pack("N") + write_payload_0)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq write_request_id_0
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end

              io.remote.in.write ([write_payload_1.length].pack("N") + write_payload_1)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_STATUS.new({}).decode(payload)
              expect( packet[:"request-id"] ).to eq write_request_id_1
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_OK
              if version >= 3
                expect( packet[:"error message"] ).to eq "Success"
                expect( packet[:"language tag"]  ).to eq ""
              end

              io.remote.in.write ([close_payload.length].pack("N") + close_payload)
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
              io.remote.in.write ([write_payload.length].pack("N") + write_payload)
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
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              io.remote.in.write ([close_payload.length].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              FileUtils.remove_entry_secure filename
            end

            it "returns attrs response" do
              io.remote.in.write ([fstat_payload.length].pack("N") + fstat_payload)
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
              io.remote.in.write ([fstat_payload.length].pack("N") + fstat_payload)
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

            before :example do
              File.open(filename, "w"){ |f| f.write content }
              io.remote.in.write ([open_payload.length].pack("N") + open_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              io.remote.in.write ([close_payload.length].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              FileUtils.remove_entry_secure filename
            end

            it "returns status response" do
              io.remote.in.write ([fsetstat_payload.length].pack("N") + fsetstat_payload)
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
              expect( File.stat(filename).mode       ).to eq newattrs[:"permissions"]
              expect( File.stat(filename).atime.to_i ).to eq newattrs[:"atime"]
              expect( File.stat(filename).mtime.to_i ).to eq newattrs[:"mtime"]
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
              io.remote.in.write ([fsetstat_payload.length].pack("N") + fsetstat_payload)
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
              io.remote.in.write ([opendir_payload.length].pack("N") + opendir_payload)
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
              io.remote.in.write ([opendir_payload.length].pack("N") + opendir_payload)
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
              io.remote.in.write ([opendir_payload.length].pack("N") + opendir_payload)
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
              io.remote.in.write ([opendir_payload.length].pack("N") + opendir_payload)
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
              io.remote.in.write ([opendir_payload.length].pack("N") + opendir_payload)
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
              File.lchmod(0700, path)
              File.lchmod(0600, File.join(path, file))
              File.lchmod(0400, File.join(path, symlink))
              File.lutime(0, 0, path)
              time = Time.new(Time.now.year, 1, 2, 3, 4, nil, Time.now.utc_offset)
              File.lutime(time, time, File.join(path, file))
              File.lutime(0, 0, File.join(path, symlink))
              io.remote.in.write ([opendir_payload.length].pack("N") + opendir_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              packet = version_class::Packet::SSH_FXP_HANDLE.new({}).decode(payload)
              @handle = packet[:"handle"]
            end

            after :example do
              io.remote.in.write ([close_payload.length].pack("N") + close_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              FileUtils.remove_entry_secure path
            end

            it "returns name and then EOF status response" do
              io.remote.in.write ([readdir_payload_0.length].pack("N") + readdir_payload_0)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_NAME::TYPE
              packet = version_class::Packet::SSH_FXP_NAME.new({}).decode(payload)
              expect( packet[:"request-id"]  ).to eq readdir_request_id_0
              expect( packet[:"count"]       ).to eq 4
              expect( packet[:"filename[0]"] ).to eq "."
              expect( packet[:"longname[0]"] ).to match /drwx------ ... ........ ........      128 Jan  1  1970 \./
              expect( packet[:"attrs[0]"]    ).to eq path_attrs
              expect( packet[:"filename[1]"] ).to eq ".."
              expect( packet[:"longname[1]"] ).to match /.......... ... ........ ........ ........ ... .. ..... \.\./
              expect( packet[:"attrs[1]"]    ).to eq parent_attrs
              expect( packet[:"filename[2]"] ).to eq symlink
              expect( packet[:"longname[2]"] ).to match /lr--------   1 ........ ........        9 Jan  1  1970 #{symlink}/
              expect( packet[:"attrs[2]"]    ).to eq symlink_attrs
              expect( packet[:"filename[3]"] ).to eq file
              expect( packet[:"longname[3]"] ).to match /-rw-------   1 ........ ........        0 Jan  2 03:04 #{file}/
              expect( packet[:"attrs[3]"]    ).to eq file_attrs

              io.remote.in.write ([readdir_payload_1.length].pack("N") + readdir_payload_1)
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
              io.remote.in.write ([readdir_payload.length].pack("N") + readdir_payload)
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
              io.remote.in.write ([remove_payload.length].pack("N") + remove_payload)
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
              io.remote.in.write ([remove_payload.length].pack("N") + remove_payload)
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
              io.remote.in.write ([remove_payload.length].pack("N") + remove_payload)
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
              io.remote.in.write ([remove_payload.length].pack("N") + remove_payload)
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
            }
          }
          let(:mkdir_payload){
            version_class::Packet::SSH_FXP_MKDIR.new({}).encode(mkdir_packet)
          }
          let(:request_id){ 1 }

          context "when request is valid" do
            let(:path){ "newdir" }

            after :example do
              FileUtils.remove_entry_secure(path)
            end

            it "returns status response" do
              io.remote.in.write ([mkdir_payload.length].pack("N") + mkdir_payload)
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
              io.remote.in.write ([mkdir_payload.length].pack("N") + mkdir_payload)
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
              io.remote.in.write ([mkdir_payload.length].pack("N") + mkdir_payload)
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
              io.remote.in.write ([mkdir_payload.length].pack("N") + mkdir_payload)
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
              io.remote.in.write ([rmdir_payload.length].pack("N") + rmdir_payload)
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
              io.remote.in.write ([rmdir_payload.length].pack("N") + rmdir_payload)
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
              io.remote.in.write ([rmdir_payload.length].pack("N") + rmdir_payload)
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
              io.remote.in.write ([rmdir_payload.length].pack("N") + rmdir_payload)
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
              io.remote.in.write ([rmdir_payload.length].pack("N") + rmdir_payload)
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
              io.remote.in.write ([rmdir_payload.length].pack("N") + rmdir_payload)
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
            let(:oldpath){ "oldfile" }
            let(:newpath){ "newfile" }

            before :example do
              FileUtils.touch(oldpath)
            end

            after :example do
              FileUtils.remove_entry_secure(newpath)
            end

            it "returns status response" do
              expect( File.exist?(oldpath) ).to be true
              expect( File.exist?(newpath) ).to be false
              io.remote.in.write ([rename_payload.length].pack("N") + rename_payload)
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

          context "when request oldpath does not exist" do
            let(:request_id){ 1 }
            let(:oldpath){ "does/not/exist" }
            let(:newpath){ "dummy" }

            it "returns status response" do
              io.remote.in.write ([rename_payload.length].pack("N") + rename_payload)
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
            let(:oldpath){ "dir000/oldfile" }
            let(:newpath){ "dir000/newfile" }

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
              io.remote.in.write ([rename_payload.length].pack("N") + rename_payload)
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
            let(:oldpath){ "oldfile" }
            let(:newpath){ ("a".."z").to_a.join * 10 }

            before :example do
              FileUtils.touch(oldpath)
            end

            after :example do
              FileUtils.remove_entry_secure(oldpath)
            end

            it "returns status response" do
              io.remote.in.write ([rename_payload.length].pack("N") + rename_payload)
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
      end
    end
  end
end
