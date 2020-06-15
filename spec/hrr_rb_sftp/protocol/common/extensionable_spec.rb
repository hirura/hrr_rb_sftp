RSpec.describe HrrRbSftp::Protocol::Common::Extensionable do
  let(:mixed_in){
    Class.new do |klass|
      include HrrRbSftp::Protocol::Common::Extensionable
    end
  }
  let(:handles){
    {}
  }
  let(:logger){
    "logger"
  }

  describe ".new" do
    it "takes handles and logger arguments" do
      expect{ mixed_in.new(handles, logger: logger) }.not_to raise_error
    end
  end
end
