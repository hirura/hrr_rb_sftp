RSpec.describe HrrRbSftp::Protocol::Version3::Extensions::PosixRenameAtOpensshCom do
  it "inherits Extension class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Version3::Extensions::Extension
  end

  let(:extension_name){ "posix-rename@openssh.com" }
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
      {:version => HrrRbSftp::Protocol::Version3::PROTOCOL_VERSION},
    ]
  }

  let(:packet){
    {
      :"type"             => HrrRbSftp::Protocol::Version3::Packets::SSH_FXP_EXTENDED::TYPE,
      :"request-id"       => 1,
      :"extended-request" => "posix-rename@openssh.com",
      :"oldpath"          => "oldpath",
      :"newpath"          => "newpath",
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version3::DataTypes::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version3::DataTypes::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version3::DataTypes::String.encode(packet[:"extended-request"]),
      HrrRbSftp::Protocol::Version3::DataTypes::String.encode(packet[:"oldpath"]),
      HrrRbSftp::Protocol::Version3::DataTypes::String.encode(packet[:"newpath"]),
    ].join
  }

  describe "#encode" do
    it "returns payload encoded" do
      expect(HrrRbSftp::Protocol::Version3::Packets::SSH_FXP_EXTENDED.new(*pkt_args).encode(packet)).to eq payload
    end
  end

  describe "#decode" do
    it "returns packet decoded" do
      expect(HrrRbSftp::Protocol::Version3::Packets::SSH_FXP_EXTENDED.new(*pkt_args).decode(payload)).to eq packet
    end
  end
end
