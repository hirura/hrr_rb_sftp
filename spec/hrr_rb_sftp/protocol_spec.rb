RSpec.describe HrrRbSftp::Protocol do
  dummy_version = 987654321

  before :all do
    @dummy_klass = Class.new(described_class) do |klass|
      klass::PROTOCOL_VERSION = dummy_version
    end
  end

  after :all do
    described_class.instance_variable_get("@subclasses").delete @dummy_klass
  end

  describe ".versions" do
    it "returns {protocol_version => subclass} Hash" do
      expect( described_class.versions ).to include(dummy_version => @dummy_klass)
    end
  end
end
