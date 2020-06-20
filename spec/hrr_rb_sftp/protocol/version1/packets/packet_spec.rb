RSpec.describe HrrRbSftp::Protocol::Version1::Packets::Packet do
  it "inherits Common::Packets::Packet class" do
    expect( described_class ).to be < HrrRbSftp::Protocol::Common::Packets::Packet
  end

  let(:subclass){
    Class.new(described_class)
  }
  let(:pkt_args){
    [
      context,
    ]
  }
  let(:context){
    {
      :version => version,
      :handles => handles,
    }
  }
  let(:version){
    "version"
  }
  let(:handles){
    "handles"
  }
  let(:logger){
    "logger"
  }

  describe ".new" do
    it "takes context and logger arguments" do
      expect{ subclass.new(context, logger: logger) }.not_to raise_error
    end
  end

  describe "#context" do
    it "returns context" do
      expect( subclass.new(context, logger: logger).context ).to be context
    end
  end

  describe "#version" do
    it "returns version" do
      expect( subclass.new(context, logger: logger).version ).to be version
    end
  end

  describe "#handles" do
    it "returns handles" do
      expect( subclass.new(context, logger: logger).handles ).to be handles
    end
  end
end
