RSpec.describe HrrRbSftp::Protocol::Version1::Packet::SSH_FXP_OPEN do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  let(:type){ 3 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  describe "#{described_class}::SSH_FXF_READ" do
    let(:value){ 0x00000001 }

    it "is defined" do
      expect(described_class::SSH_FXF_READ).to eq value
    end
  end

  describe "#{described_class}::SSH_FXF_WRITE" do
    let(:value){ 0x00000002 }

    it "is defined" do
      expect(described_class::SSH_FXF_WRITE).to eq value
    end
  end

  describe "#{described_class}::SSH_FXF_APPEND" do
    let(:value){ 0x00000004 }

    it "is defined" do
      expect(described_class::SSH_FXF_APPEND).to eq value
    end
  end

  describe "#{described_class}::SSH_FXF_CREAT" do
    let(:value){ 0x00000008 }

    it "is defined" do
      expect(described_class::SSH_FXF_CREAT).to eq value
    end
  end

  describe "#{described_class}::SSH_FXF_TRUNC" do
    let(:value){ 0x00000010 }

    it "is defined" do
      expect(described_class::SSH_FXF_TRUNC).to eq value
    end
  end

  describe "#{described_class}::SSH_FXF_EXCL" do
    let(:value){ 0x00000020 }

    it "is defined" do
      expect(described_class::SSH_FXF_EXCL).to eq value
    end
  end

  let(:packet){
    {
      :"type"       => type,
      :"request-id" => 1,
      :"filename"   => "filename",
      :"pflags"     => (described_class::SSH_FXF_READ | described_class::SSH_FXF_WRITE),
      :"attrs"      => {},
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Version1::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Version1::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Version1::DataType::String.encode(packet[:"filename"]),
      HrrRbSftp::Protocol::Version1::DataType::Uint32.encode(packet[:"pflags"]),
      HrrRbSftp::Protocol::Version1::DataType::Attrs.encode(packet[:"attrs"]),
    ].join
  }

  describe "#encode" do
    it "returns payload encoded" do
      expect(described_class.new.encode(packet)).to eq payload
    end
  end

  describe "#decode" do
    it "returns packet decoded" do
      expect(described_class.new.decode(payload)).to eq packet
    end
  end
end
