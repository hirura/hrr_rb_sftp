RSpec.describe HrrRbSftp::Protocol::Version3::Extension::HardlinkAtOpensshCom do
  it "includes Common::Extensionable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Extensionable)
  end

  let(:extension_name){ "hardlink@openssh.com" }
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
      {:extension => HrrRbSftp::Protocol::Version3::Extension},
    ]
  }

  let(:packet){
    {
      :"type"             => HrrRbSftp::Protocol::Version3::Packet::SSH_FXP_EXTENDED::TYPE,
      :"request-id"       => 1,
      :"extended-request" => "hardlink@openssh.com",
      :"oldpath"          => "oldpath",
      :"newpath"          => "newpath",
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version3::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version3::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version3::DataType::String.encode(packet[:"extended-request"]),
      HrrRbSftp::Protocol::Version3::DataType::String.encode(packet[:"oldpath"]),
      HrrRbSftp::Protocol::Version3::DataType::String.encode(packet[:"newpath"]),
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
