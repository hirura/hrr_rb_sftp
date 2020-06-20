RSpec.describe HrrRbSftp::Protocol::Common::Packets::SSH_FXP_VERSION do
  let(:type){ 2 }

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
      :"version"    => 1,
      :"extensions" => [{:"extension-name" => "name1", :"extension-data" => "data1"}, {:"extension-name" => "name1", :"extension-data" => "data1"}],
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Common::DataTypes::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Common::DataTypes::Uint32.encode(packet[:"version"]),
      HrrRbSftp::Protocol::Common::DataTypes::ExtensionPairs.encode(packet[:"extensions"]),
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
