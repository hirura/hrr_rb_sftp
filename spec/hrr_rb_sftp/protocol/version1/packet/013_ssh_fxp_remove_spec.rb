RSpec.describe HrrRbSftp::Protocol::Version1::Packet::SSH_FXP_REMOVE do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  let(:type){ 13 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  let(:packet){
    {
      :"type"       => type,
      :"request-id" => 1,
      :"filename"   => "filename",
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version1::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version1::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version1::DataType::String.encode(packet[:"filename"]),
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