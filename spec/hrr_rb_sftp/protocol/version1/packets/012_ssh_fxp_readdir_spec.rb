RSpec.describe HrrRbSftp::Protocol::Version1::Packets::SSH_FXP_READDIR do
  it "inherits Version1::Packets::Packet class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Version1::Packets::Packet
  end

  let(:type){ 12 }

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
      :"handle"     => "handle",
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version1::DataTypes::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version1::DataTypes::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version1::DataTypes::String.encode(packet[:"handle"]),
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
