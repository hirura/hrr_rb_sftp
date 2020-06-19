RSpec.describe HrrRbSftp::Protocol::Version1::Packets::SSH_FXP_NAME do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  let(:type){ 104 }

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
      :"type"        => type,
      :"request-id"  => 1,
      :"count"       => 2,
      :"filename[0]" => "filename0",
      :"longname[0]" => "longname0",
      :"attrs[0]"    => {},
      :"filename[1]" => "filename1",
      :"longname[1]" => "longname1",
      :"attrs[1]"    => {},
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version1::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version1::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version1::DataType::Uint32.encode(packet[:"count"]),
      HrrRbSftp::Protocol::Version1::DataType::String.encode(packet[:"filename[0]"]),
      HrrRbSftp::Protocol::Version1::DataType::String.encode(packet[:"longname[0]"]),
      HrrRbSftp::Protocol::Version1::DataType::Attrs.encode(packet[:"attrs[0]"]),
      HrrRbSftp::Protocol::Version1::DataType::String.encode(packet[:"filename[1]"]),
      HrrRbSftp::Protocol::Version1::DataType::String.encode(packet[:"longname[1]"]),
      HrrRbSftp::Protocol::Version1::DataType::Attrs.encode(packet[:"attrs[1]"]),
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
