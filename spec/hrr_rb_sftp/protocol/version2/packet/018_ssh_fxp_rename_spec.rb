RSpec.describe HrrRbSftp::Protocol::Version2::Packets::SSH_FXP_RENAME do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  let(:type){ 18 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  let(:pkt_args){
    [
      {},
    ]
  }

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
      HrrRbSftp::Protocol::Version2::DataTypes::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version2::DataTypes::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version2::DataTypes::String.encode(packet[:"oldpath"]),
      HrrRbSftp::Protocol::Version2::DataTypes::String.encode(packet[:"newpath"]),
    ].join
  }

  describe "#encode" do
    it "returns payload encoded" do
      expect(described_class.new(*pkt_args).encode(packet)).to eq payload
    end
  end

  describe "#decode" do
    it "returns packet decoded" do
      expect(described_class.new(*pkt_args).decode(payload)).to eq packet
    end
  end
end
