RSpec.describe HrrRbSftp::Protocol::Version2::Packet do
  it "has packet classes defined in version 1" do
    expect( described_class.constants ).to include(*HrrRbSftp::Protocol::Version1::Packet.constants)
  end
end
