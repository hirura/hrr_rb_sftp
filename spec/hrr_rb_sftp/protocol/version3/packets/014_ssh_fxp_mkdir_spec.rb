RSpec.describe HrrRbSftp::Protocol::Version3::Packets::SSH_FXP_MKDIR do
  it "inherits Version1::Packets::SSH_FXP_MKDIR class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Version1::Packets::SSH_FXP_MKDIR
  end

  let(:type){ 14 }

  let(:pkt_args){
    [
      {:version => HrrRbSftp::Protocol::Version3::PROTOCOL_VERSION},
    ]
  }

  let(:packet){
    {
      :"type"       => type,
      :"request-id" => 1,
      :"path"       => "path",
      :"attrs"      => {},
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version3::DataTypes::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version3::DataTypes::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version3::DataTypes::String.encode(packet[:"path"]),
      HrrRbSftp::Protocol::Version3::DataTypes::Attrs.encode(packet[:"attrs"]),
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
