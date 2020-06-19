RSpec.describe HrrRbSftp::Protocol::Version1::Packets::SSH_FXP_STATUS do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  let(:type){ 101 }

  describe "#{described_class}::TYPE" do
    it "is defined" do
      expect(described_class::TYPE).to eq type
    end
  end

  describe "#{described_class}::SSH_FX_OK" do
    let(:value){ 0 }

    it "is defined" do
      expect(described_class::SSH_FX_OK).to eq value
    end
  end

  describe "#{described_class}::SSH_FX_EOF" do
    let(:value){ 1 }

    it "is defined" do
      expect(described_class::SSH_FX_EOF).to eq value
    end
  end

  describe "#{described_class}::SSH_FX_NO_SUCH_FILE" do
    let(:value){ 2 }

    it "is defined" do
      expect(described_class::SSH_FX_NO_SUCH_FILE).to eq value
    end
  end

  describe "#{described_class}::SSH_FX_PERMISSION_DENIED" do
    let(:value){ 3 }

    it "is defined" do
      expect(described_class::SSH_FX_PERMISSION_DENIED).to eq value
    end
  end

  describe "#{described_class}::SSH_FX_FAILURE" do
    let(:value){ 4 }

    it "is defined" do
      expect(described_class::SSH_FX_FAILURE).to eq value
    end
  end

  describe "#{described_class}::SSH_FX_BAD_MESSAGE" do
    let(:value){ 5 }

    it "is defined" do
      expect(described_class::SSH_FX_BAD_MESSAGE).to eq value
    end
  end

  describe "#{described_class}::SSH_FX_NO_CONNECTION" do
    let(:value){ 6 }

    it "is defined" do
      expect(described_class::SSH_FX_NO_CONNECTION).to eq value
    end
  end

  describe "#{described_class}::SSH_FX_CONNECTION_LOST" do
    let(:value){ 7 }

    it "is defined" do
      expect(described_class::SSH_FX_CONNECTION_LOST).to eq value
    end
  end

  describe "#{described_class}::SSH_FX_OP_UNSUPPORTED" do
    let(:value){ 8 }

    it "is defined" do
      expect(described_class::SSH_FX_OP_UNSUPPORTED).to eq value
    end
  end

  let(:pkt_args){
    [
      {},
    ]
  }

  let(:packet){
    {
      :"type"       => type,
      :"request-id" => 1,
      :"code"       => described_class::SSH_FX_OK,
    }
  }
  let(:payload){
    [
      HrrRbSftp::Protocol::Common::DataType::Byte.encode(packet[:"type"]),
      HrrRbSftp::Protocol::Common::DataType::Uint32.encode(packet[:"request-id"]),
      HrrRbSftp::Protocol::Common::DataType::Uint32.encode(packet[:"code"]),
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
