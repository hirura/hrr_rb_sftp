RSpec.describe HrrRbSftp::Protocol::Version1::Packet do
  it "includes HrrRbSftp::Protocol::Common::Packetable" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end

  describe ".list" do
    dummy_type = 255

    before :all do
      @dummy_klass = Class.new(described_class) do |klass|
        klass::TYPE = dummy_type
      end
    end

    after :all do
      described_class.instance_variable_get("@subclasses").delete @dummy_klass
    end

    it "includes inherited classes" do
      expect( described_class.list ).to include(@dummy_klass)
    end
  end
end
