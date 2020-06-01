RSpec.describe HrrRbSftp::Protocol::Version1::Packet do
  describe ".list" do
    before :all do
      described_class.send(:const_set, :SSH_FXP_DUMMY, Class.new)
    end

    after :all do
      described_class.send(:remove_const, :SSH_FXP_DUMMY)
    end

    it "includes SSH_FXP_XXX classes" do
      expect( described_class.list ).to include(described_class::SSH_FXP_DUMMY)
    end
  end
end
