RSpec.describe HrrRbSftp::Protocol::Version2::DataType do
  it "has data types as same as version 1" do
    expect( described_class.constants ).to eq HrrRbSftp::Protocol::Version1::DataType.constants
  end
end
