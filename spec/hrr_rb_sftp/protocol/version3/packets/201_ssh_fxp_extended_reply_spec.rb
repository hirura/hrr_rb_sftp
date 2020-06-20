RSpec.describe HrrRbSftp::Protocol::Version3::Packets::SSH_FXP_EXTENDED_REPLY do
  it "inherits Version3::Packets::Packet class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Version3::Packets::Packet
  end

  let(:type){ 201 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  let(:pkt_args){
    [
      {:version => HrrRbSftp::Protocol::Version3::PROTOCOL_VERSION},
    ]
  }

  let(:packet){
    {
      :"type"             => type,
      :"request-id"       => 1,
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version3::DataTypes::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version3::DataTypes::Uint32.encode(packet[:"request-id"]),
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
