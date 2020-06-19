RSpec.describe HrrRbSftp::Protocol::Version3::Extension::LsetstatAtOpensshCom do
  it "includes Common::Extensionable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Extensionable)
  end

  let(:extension_name){ "lsetstat@openssh.com" }
  let(:extension_data){ "1" }

  describe "#{described_class}::EXTENSION_NAME" do
    it "is defined" do
      expect(described_class::EXTENSION_NAME).to eq extension_name
    end
  end

  describe "#{described_class}::EXTENSION_DATA" do
    it "is defined" do
      expect(described_class::EXTENSION_DATA).to eq extension_data
    end
  end

  let(:pkt_args){
    [
      {},
    ]
  }

  let(:packet){
    {
      :"type"             => HrrRbSftp::Protocol::Version3::Packet::SSH_FXP_EXTENDED::TYPE,
      :"request-id"       => 1,
      :"extended-request" => "lsetstat@openssh.com",
      :"path"             => "path",
      :"attrs"            => {},
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version3::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version3::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version3::DataType::String.encode(packet[:"extended-request"]),
      HrrRbSftp::Protocol::Version3::DataType::String.encode(packet[:"path"]),
      HrrRbSftp::Protocol::Version3::DataType::Attrs.encode(packet[:"attrs"]),
    ].join
  }

  describe "#encode" do
    it "returns payload encoded" do
      expect(HrrRbSftp::Protocol::Version3::Packet::SSH_FXP_EXTENDED.new(*pkt_args).encode(packet)).to eq payload
    end
  end

  describe "#decode" do
    it "returns packet decoded" do
      expect(HrrRbSftp::Protocol::Version3::Packet::SSH_FXP_EXTENDED.new(*pkt_args).decode(payload)).to eq packet
    end
  end
end
