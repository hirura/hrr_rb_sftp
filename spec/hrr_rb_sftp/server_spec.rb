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

    [1, 2].each do |version|
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

    [1, 2].each do |version|
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
          end
        end
      end
    end
  end
end
