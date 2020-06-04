RSpec.describe HrrRbSftp::Protocol do
  dummy_version = "X"

  before :all do
    dummy_class = Class.new do |klass|
      klass::PROTOCOL_VERSION = dummy_version
    end
    described_class.send(:const_set, :"Version#{dummy_version}", dummy_class)
  end

  after :all do
    described_class.send(:remove_const, "Version#{dummy_version}")
  end

  describe ".versions" do
    it "returns {protocol_version => subclass} Hash" do
      expect( described_class.versions ).to include(dummy_version)
    end
  end
end
