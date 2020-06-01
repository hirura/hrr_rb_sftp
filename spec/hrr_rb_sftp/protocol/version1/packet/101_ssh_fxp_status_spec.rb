RSpec.describe HrrRbSftp::Protocol::Version1::Packet::SSH_FXP_STATUS do
  let(:type){ 101 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  let(:packet){
    {
      :"type"       => type,
      :"request-id" => 1,
      :"code"       => described_class::SSH_FX_OK,
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Common::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Common::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Common::DataType::Uint32.encode(packet[:"code"]),
    ].join
  }

  describe "#encode" do
    it "returns payload encoded" do
      expect(described_class.new.encode(packet)).to eq payload
    end
  end

  describe "#decode" do
    it "returns packet decoded" do
      expect(described_class.new.decode(payload)).to eq packet
    end
  end
end
