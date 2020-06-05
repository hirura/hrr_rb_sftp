RSpec.describe HrrRbSftp::Protocol::Version2::Packet::SSH_FXP_RENAME do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  let(:type){ 18 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  let(:packet){
    {
      :"type"       => type,
      :"request-id" => 1,
      :"oldpath"    => "old",
      :"newpath"    => "new",
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version2::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version2::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version2::DataType::String.encode(packet[:"oldpath"]),
      HrrRbSftp::Protocol::Version2::DataType::String.encode(packet[:"newpath"]),
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
