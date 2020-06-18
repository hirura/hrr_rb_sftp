RSpec.describe HrrRbSftp::Protocol::Version3::Packet::SSH_FXP_STATUS do
  it "inherits Version1::Packet::SSH_FXP_STATUS class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Version1::Packet::SSH_FXP_STATUS
  end

  let(:type){ 101 }

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
      HrrRbSftp::Protocol::Common::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Common::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Common::DataType::Uint32.encode(packet[:"code"]),
      HrrRbSftp::Protocol::Common::DataType::String.encode(packet[:"error message"]),
      HrrRbSftp::Protocol::Common::DataType::String.encode(packet[:"language tag"]),
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
