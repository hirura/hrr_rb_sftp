RSpec.describe HrrRbSftp::Protocol::Common::Packet do
  it "includes Common::Packetable module" do
    expect( described_class ).to include(HrrRbSftp::Protocol::Common::Packetable)
  end
end
