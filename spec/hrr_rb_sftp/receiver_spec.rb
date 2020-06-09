RSpec.describe HrrRbSftp::Receiver do
  let(:io_in){ StringIO.new String.new, 'r+' }

  after :example do
    io_in.close rescue nil
  end

  describe ".new" do
    it "takes io_in argument" do
      expect{ described_class.new io_in }.not_to raise_error
    end
  end

  describe "#receive" do
    let(:receiver){ described_class.new io_in }
    let(:payload){ "testing" }
    let(:payload_with_length){ [payload.bytesize.to_s.rjust(8, "0"), payload].pack("H8" "a#{payload.bytesize}") }

    context "when receiving correct payload" do
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

    context "when io_in is closed before receiving packet length" do
      before :example do
        io_in.close_write
      end

      it "returns nil" do
        expect(receiver.receive).to be nil
      end
    end

    context "when io_in is closed during receiving packet length" do
      before :example do
        io_in.write payload_with_length[0,1]
        io_in.close_write
        io_in.rewind
      end

      it "returns nil" do
        expect(receiver.receive).to be nil
      end
    end

    context "when io_in is closed before receiving payload" do
      before :example do
        io_in.write payload_with_length[0,4]
        io_in.close_write
        io_in.rewind
      end

      it "returns nil" do
        expect(receiver.receive).to be nil
      end
    end

    context "when io_in is closed during receiving payload" do
      before :example do
        io_in.write payload_with_length[0,5]
        io_in.close_write
        io_in.rewind
      end

      it "returns nil" do
        expect(receiver.receive).to be nil
      end
    end
  end
end
