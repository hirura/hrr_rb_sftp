RSpec.describe HrrRbSftp::Protocol::Common::Packet do
  let(:subclass){
    Class.new(described_class) do |klass|
      klass::FORMAT = [
        [HrrRbSftp::Protocol::Common::DataType::Uint32, :'request-id'],
        [HrrRbSftp::Protocol::Common::DataType::String, :'data'      ],
      ]
    end
  }

  describe ".new" do
    it "does not take arguments" do
      expect{ subclass.new }.not_to raise_error
    end
  end

  describe "#encode" do
    packet = {:'request-id' => 123, :'data' => 'testing'}

    context "when each arg is acceptable by data_type" do
      it "encodes #{packet.inspect} to \"00 00 00 7B 00 00 00 07 t e s t i n g\"" do
        expect( subclass.new.encode( packet ) ).to eq( ["0000007B", "00000007", "testing"].pack("H*H*a*") )
      end
    end

    context "when an arg is not acceptable by data_type" do
      it "raises an error" do
        expect { subclass.new.encode( {:'request-id' => 123, :'data' => nil} ) }.to raise_error ArgumentError
      end
    end
  end

  describe "#decode" do
    packet = {:'request-id' => 123, :'data' => 'testing'}

    it "decodes \"00 00 00 7B 00 00 00 07 t e s t i n g\" to #{packet.inspect}" do
      expect( subclass.new.decode( ["0000007B", "00000007", "testing"].pack("H*H*a*") ) ).to eq packet
    end
  end
end
