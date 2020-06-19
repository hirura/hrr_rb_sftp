RSpec.describe HrrRbSftp::Protocol::Version1::Packet::SSH_FXP_ATTRS do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  let(:type){ 105 }

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
      :"type"        => type,
      :"request-id"  => 1,
      :"attrs"       => {},
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version1::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version1::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version1::DataType::Attrs.encode(packet[:"attrs"]),
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
