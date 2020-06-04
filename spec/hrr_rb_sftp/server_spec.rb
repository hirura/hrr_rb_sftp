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
      HrrRbSftp::Protocol::Common::Packet::SSH_FXP_INIT.new.encode(init_packet)
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
          packet = HrrRbSftp::Protocol::Common::Packet::SSH_FXP_VERSION.new.decode(payload)
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
      HrrRbSftp::Protocol::Common::Packet::SSH_FXP_INIT.new.encode(init_packet)
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
            packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
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
            packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
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
            packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
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
            version_class::Packet::SSH_FXP_REALPATH.new.encode(realpath_packet)
          }

          context "when request is valid" do
            let(:request_id){ 1 }
            let(:path){ "." }

            it "returns name response" do
              io.remote.in.write ([realpath_payload.length].pack("N") + realpath_payload)
              payload_length = io.remote.out.read(4).unpack("N")[0]
              payload = io.remote.out.read(payload_length)
              expect( payload[0].unpack("C")[0] ).to eq version_class::Packet::SSH_FXP_NAME::TYPE
              packet = version_class::Packet::SSH_FXP_NAME.new.decode(payload)
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
            version_class::Packet::SSH_FXP_STAT.new.encode(stat_packet)
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
              packet = version_class::Packet::SSH_FXP_ATTRS.new.decode(payload)
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
              packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
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
              packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
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
              packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to match /File name too long(?: @ rb_file_s_stat)? - #{path}/
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
            version_class::Packet::SSH_FXP_RENAME.new.encode(rename_packet)
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
              packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
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
              packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
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
              packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
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
              packet = version_class::Packet::SSH_FXP_STATUS.new.decode(payload)
              expect( packet[:"request-id"] ).to eq request_id
              expect( packet[:"code"]       ).to eq version_class::Packet::SSH_FXP_STATUS::SSH_FX_FAILURE
              if version >= 3
                expect( packet[:"error message"] ).to match /File name too long(?: @ rb_file_s_rename)? - \(#{oldpath}, #{newpath}\)/
                expect( packet[:"language tag"]  ).to eq ""
              end
            end
          end
        end
      end
    end
  end
end
