RSpec.describe HrrRbSftp::Protocol::Version2::Packet do
  it "has packet classes as same as version 1" do
    expect( described_class.constants ).to eq HrrRbSftp::Protocol::Version1::Packet.constants
  end

  describe ".list" do
    it "returns packet classes as same as version 1" do
      expect( described_class.list ).to eq HrrRbSftp::Protocol::Version1::Packet.list
    end

    context "when the version has new classes" do
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
end
