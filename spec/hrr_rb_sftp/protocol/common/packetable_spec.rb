RSpec.describe HrrRbSftp::Protocol::Common::Packetable do
  let(:mixed_in){
    Class.new do |klass|
      klass.include HrrRbSftp::Protocol::Common::Packetable
      klass::TYPE = 255
      klass::FORMAT = [
        [HrrRbSftp::Protocol::Common::DataType::Uint32, :"request-id"],
        [HrrRbSftp::Protocol::Common::DataType::String, :"data"      ],
      ]
    end
  }

  describe ".new" do
    it "does not take arguments" do
      expect{ mixed_in.new }.not_to raise_error
    end
  end

  describe "#encode" do
    packet = {:"request-id" => 123, :"data" => "testing"}

    context "when each arg is acceptable by data_type" do
      it "encodes #{packet.inspect} to \"FF 00 00 00 7B 00 00 00 07 t e s t i n g\"" do
        expect( mixed_in.new.encode( packet ) ).to eq( ["FF", "0000007B", "00000007", "testing"].pack("H*H*H*a*") )
      end
    end

    context "when an arg is not acceptable by data_type" do
      it "raises an error" do
        expect { mixed_in.new.encode( {:"request-id" => 123, :"data" => nil} ) }.to raise_error ArgumentError
      end
    end
  end

  describe "#decode" do
    packet = {:"request-id" => 123, :"data" => "testing"}

    it "decodes \"FF 00 00 00 7B 00 00 00 07 t e s t i n g\" to #{packet.inspect}" do
      expect( mixed_in.new.decode( ["FF", "0000007B", "00000007", "testing"].pack("H*H*H*a*") ) ).to eq packet
    end
  end
end
