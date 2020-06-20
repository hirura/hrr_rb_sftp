RSpec.describe HrrRbSftp::Protocol::Version3::Packets::SSH_FXP_STATUS do
  it "inherits Version1::Packets::SSH_FXP_STATUS class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Version1::Packets::SSH_FXP_STATUS
  end

  let(:type){ 101 }

  let(:pkt_args){
    context = {}
    [
      context.update({:extensions => HrrRbSftp::Protocol::Version3::Extensions.new(context)}),
    ]
  }

  let(:packet){
    {
      :"type"          => type,
      :"request-id"    => 1,
      :"code"          => described_class::SSH_FX_OK,
      :"error message" => "abcdefg",
      :"language tag"  => "vwxyz",
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Common::DataTypes::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Common::DataTypes::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Common::DataTypes::Uint32.encode(packet[:"code"]),
      HrrRbSftp::Protocol::Common::DataTypes::String.encode(packet[:"error message"]),
      HrrRbSftp::Protocol::Common::DataTypes::String.encode(packet[:"language tag"]),
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
