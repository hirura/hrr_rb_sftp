RSpec.describe HrrRbSftp::Sender do
  let(:io_out){ StringIO.new String.new, 'r+' }

  describe ".new" do
    it "takes io_out argument" do
      expect{ described_class.new io_out }.not_to raise_error
    end
  end

  describe "#send" do
    let(:sender){ described_class.new io_out }
    let(:payload){ "testing" }

    it "sends payload length first" do
      sender.send payload
      io_out.pos = 0
      expect(io_out.read(4)).to eq [payload.length.to_s.rjust(8, "0")].pack("H8")
    end

    it "then sends payload" do
      sender.send payload
      io_out.pos = 4
      expect(io_out.read(payload.length)).to eq payload
    end

    it "does not send any extra payloads" do
      sender.send payload
      io_out.pos = 11
      expect(io_out.eof?).to be true
    end
  end
end
