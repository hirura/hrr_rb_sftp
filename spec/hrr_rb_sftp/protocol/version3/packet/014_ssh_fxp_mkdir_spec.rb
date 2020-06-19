RSpec.describe HrrRbSftp::Protocol::Version3::Packets::SSH_FXP_MKDIR do
  it "inherits Version1::Packets::SSH_FXP_MKDIR class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Version1::Packets::SSH_FXP_MKDIR
  end

  let(:type){ 14 }

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
      :"path"       => "path",
      :"attrs"      => {},
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version3::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version3::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version3::DataType::String.encode(packet[:"path"]),
      HrrRbSftp::Protocol::Version3::DataType::Attrs.encode(packet[:"attrs"]),
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
