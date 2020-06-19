RSpec.describe HrrRbSftp::Protocol::Version3::Extensions::Extension do
  let(:subclass){
    Class.new(described_class)
  }
  let(:context){
    {
      :handles    => handles,
      :extensions => extensions,
    }
  }
  let(:handles){
    "handles"
  }
  let(:extensions){
    "extensions"
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

  describe "#handles" do
    it "returns handles" do
      expect( subclass.new(context, logger: logger).handles ).to be handles
    end
  end

  describe "#extensions" do
    it "returns extensions" do
      expect( subclass.new(context, logger: logger).extensions ).to be extensions
    end
  end
end
