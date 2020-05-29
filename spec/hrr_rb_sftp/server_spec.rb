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

  context ".new" do
    it "takes no argument" do
      expect{ described_class.new }.not_to raise_error
    end
  end

  context "#start" do
    let(:server){
      described_class.new
    }

    it "takes in, out, err arguments" do
      expect{ server.start *io.local.to_a }.not_to raise_error
    end

    it "raises an error when less than 3 arguments" do
      expect{ server.start "arg1", "arg2" }.to raise_error ArgumentError
    end

    it "raises an error when more than 3 arguments" do
      expect{ server.start "arg1", "arg2", "arg3", "arg4" }.to raise_error ArgumentError
    end
  end
end
