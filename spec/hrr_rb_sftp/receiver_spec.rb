require 'stringio'

RSpec.describe HrrRbSftp::Receiver do
  let(:io_in){ StringIO.new String.new, 'r+' }

  describe ".new" do
    it "takes io_in argument" do
      expect{ described_class.new io_in }.not_to raise_error
    end
  end

  describe "#receive" do
    let(:receiver){ described_class.new io_in }
    let(:payload){ "testing" }
    let(:payload_with_length){ [payload.length.to_s.rjust(8, "0"), payload].pack("H8" "a#{payload.length}") }

    before :example do
      io_in.write payload_with_length
      io_in.rewind
    end

    it "returns expected payload" do
      expect(receiver.receive).to eq payload
    end

    it "reads all" do
      receiver.receive
      expect(io_in.eof?).to be true
    end
  end
end
