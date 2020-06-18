RSpec.describe HrrRbSftp::Protocol::Version3::Packet::SSH_FXP_MKDIR do
  it "inherits Version1::Packet::SSH_FXP_MKDIR class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Version1::Packet::SSH_FXP_MKDIR
  end

  let(:type){ 14 }

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
      expect(described_class.new({}).encode(packet)).to eq payload
    end
  end

  describe "#decode" do
    it "returns packet decoded" do
      expect(described_class.new({}).decode(payload)).to eq packet
    end
  end
end
