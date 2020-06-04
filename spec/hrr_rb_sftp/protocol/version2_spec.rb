RSpec.describe HrrRbSftp::Protocol::Version2 do
  let(:protocol_version){ 2 }

  it "has #{described_class}::PROTOCOL_VERSION defined" do
    expect( described_class::PROTOCOL_VERSION ).to eq protocol_version
  end

  it "can be looked up in HrrRbSftp::Protocol.versions" do
    expect( HrrRbSftp::Protocol.versions ).to include(protocol_version)
  end
end
