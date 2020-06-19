RSpec.describe HrrRbSftp::Protocol::Version1::Packets::SSH_FXP_OPENDIR do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  let(:type){ 11 }

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
      :"path"       => ".",
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version1::DataTypes::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version1::DataTypes::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version1::DataTypes::String.encode(packet[:"path"]),
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
