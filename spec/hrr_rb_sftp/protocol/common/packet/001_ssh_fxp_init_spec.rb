RSpec.describe HrrRbSftp::Protocol::Common::Packet::SSH_FXP_INIT do
  let(:type){ 1 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  let(:packet){
    {
      :"version" => 1,
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Common::DataType::Byte.encode(type),
      HrrRbSftp::Protocol::Common::DataType::Uint32.encode(packet[:"version"]),
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
