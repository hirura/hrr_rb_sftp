RSpec.describe HrrRbSftp::Protocol::Version3::Packet::SSH_FXP_EXTENDED_REPLY do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  let(:type){ 201 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  let(:packet){
    {
      :"type"             => type,
      :"request-id"       => 1,
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version3::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version3::DataType::Uint32.encode(packet[:"request-id"]),
    ].join
  }

  describe "#encode" do
    it "returns payload encoded" do
      expect(described_class.new({}).encode(packet)).to eq payload
    end
  end

  describe "#decode" do
    it "returns packet decoded" do
      expect(described_class.new({}).decode(payload)).to eq packet
    end
  end
end
