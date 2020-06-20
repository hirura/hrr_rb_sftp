RSpec.describe HrrRbSftp::Protocol::Version3::Packets::SSH_FXP_SYMLINK do
  it "inherits Version3::Packets::Packet class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Version3::Packets::Packet
  end

  let(:type){ 20 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  let(:pkt_args){
    context = {}
    [
      context.update({:extensions => HrrRbSftp::Protocol::Version3::Extensions.new(context)}),
    ]
  }

  let(:packet){
    {
      :"type"       => type,
      :"request-id" => 1,
      :"targetpath" => "targetpath",
      :"linkpath"   => "linkpath",
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version3::DataTypes::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version3::DataTypes::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version3::DataTypes::String.encode(packet[:"targetpath"]),
      HrrRbSftp::Protocol::Version3::DataTypes::String.encode(packet[:"linkpath"]),
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
