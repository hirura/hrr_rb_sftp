RSpec.describe HrrRbSftp::Protocol::Common::Packetable do
  context "when mixed-in class does not have CONDITIONAL_FORMAT" do
    let(:mixed_in){
      Class.new do |klass|
        include HrrRbSftp::Protocol::Common::Packetable
        klass::TYPE = 255
        klass::FORMAT = [
          [HrrRbSftp::Protocol::Common::DataType::Byte,   :"type"],
          [HrrRbSftp::Protocol::Common::DataType::Uint32, :"request-id"],
          [HrrRbSftp::Protocol::Common::DataType::String, :"data"      ],
        ]
      end
    }

    describe ".new" do
      it "does not take arguments" do
        expect{ mixed_in.new({}) }.not_to raise_error
      end
    end

    describe "#encode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing"}

      context "when each arg is acceptable by data_type" do
        it "encodes #{packet.inspect} to \"FF 00 00 00 7B 00 00 00 07 t e s t i n g\"" do
          expect( mixed_in.new({}).encode( packet ) ).to eq( ["FF", "0000007B", "00000007", "testing"].pack("H*H*H*a*") )
        end
      end

      context "when an arg is not acceptable by data_type" do
        it "raises an error" do
          expect { mixed_in.new({}).encode( {:"type" => 255, :"request-id" => 123, :"data" => nil} ) }.to raise_error ArgumentError
        end
      end
    end

    describe "#decode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing"}

      it "decodes \"FF 00 00 00 7B 00 00 00 07 t e s t i n g\" to #{packet.inspect}" do
        expect( mixed_in.new({}).decode( ["FF", "0000007B", "00000007", "testing"].pack("H*H*H*a*") ) ).to eq packet
      end
    end
  end

  context "when mixed-in class has CONDITIONAL_FORMAT" do
    let(:mixed_in){
      Class.new do |klass|
        include HrrRbSftp::Protocol::Common::Packetable
        klass::TYPE = 255
        klass::FORMAT = [
          [HrrRbSftp::Protocol::Common::DataType::Byte,   :"type"],
          [HrrRbSftp::Protocol::Common::DataType::Uint32, :"request-id"],
          [HrrRbSftp::Protocol::Common::DataType::String, :"data"      ],
        ]
        klass::TESTING_FORMAT = [
          [HrrRbSftp::Protocol::Common::DataType::String, :"testing data"],
        ]
        klass::CONDITIONAL_FORMAT = {
          :"data" => {
            "testing" => klass::TESTING_FORMAT,
          },
        }
      end
    }

    describe ".new" do
      it "does not take arguments" do
        expect{ mixed_in.new({}) }.not_to raise_error
      end
    end

    describe "#encode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional"}

      context "when each arg is acceptable by data_type" do
        it "encodes #{packet.inspect} to \"FF 00 00 00 7B 00 00 00 07 t e s t i n g 00 00 00 0B c o n d i t i o n a l\"" do
          expect( mixed_in.new({}).encode( packet ) ).to eq( ["FF", "0000007B", "00000007", "testing", "0000000B", "conditional"].pack("H*H*H*a*H*a*") )
        end
      end

      context "when an arg is not acceptable by data_type" do
        it "raises an error" do
          expect { mixed_in.new({}).encode( {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => nil} ) }.to raise_error ArgumentError
        end
      end
    end

    describe "#decode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional"}

      it "decodes \"FF 00 00 00 7B 00 00 00 07 t e s t i n g 00 00 00 0B c o n d i t i o n a l\" to #{packet.inspect}" do
        expect( mixed_in.new({}).decode( ["FF", "0000007B", "00000007", "testing", "0000000B", "conditional"].pack("H*H*H*a*H*a*") ) ).to eq packet
      end
    end
  end

  context "when mixed-in class has chained CONDITIONAL_FORMAT" do
    let(:mixed_in){
      Class.new do |klass|
        include HrrRbSftp::Protocol::Common::Packetable
        klass::TYPE = 255
        klass::FORMAT = [
          [HrrRbSftp::Protocol::Common::DataType::Byte,   :"type"],
          [HrrRbSftp::Protocol::Common::DataType::Uint32, :"request-id"],
          [HrrRbSftp::Protocol::Common::DataType::String, :"data"      ],
        ]
        klass::TESTING_FORMAT = [
          [HrrRbSftp::Protocol::Common::DataType::String, :"testing data"],
        ]
        klass::CHAINED_FORMAT = [
          [HrrRbSftp::Protocol::Common::DataType::String, :"chained data"],
        ]
        klass::CONDITIONAL_FORMAT = {
          :"data" => {
            "testing" => klass::TESTING_FORMAT,
          },
          :"testing data" => {
            "conditional" => klass::CHAINED_FORMAT,
          },
        }
      end
    }

    describe ".new" do
      it "does not take arguments" do
        expect{ mixed_in.new({}) }.not_to raise_error
      end
    end

    describe "#encode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional", :"chained data" => "chained"}

      context "when each arg is acceptable by data_type" do
        it "encodes #{packet.inspect} to \"FF 00 00 00 7B 00 00 00 07 t e s t i n g 00 00 00 0B c o n d i t i o n a l 00 00 00 07 c h a i n e d\"" do
          expect( mixed_in.new({}).encode( packet ) ).to eq( ["FF", "0000007B", "00000007", "testing", "0000000B", "conditional", "00000007", "chained"].pack("H*H*H*a*H*a*H*a*") )
        end
      end

      context "when an arg is not acceptable by data_type" do
        it "raises an error" do
          expect { mixed_in.new({}).encode( {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional", :"chained data" => nil} ) }.to raise_error ArgumentError
        end
      end
    end

    describe "#decode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional", :"chained data" => "chained"}

      it "decodes \"FF 00 00 00 7B 00 00 00 07 t e s t i n g 00 00 00 0B c o n d i t i o n a l 00 00 00 07 c h a i n e d\" to #{packet.inspect}" do
        expect( mixed_in.new({}).decode( ["FF", "0000007B", "00000007", "testing", "0000000B", "conditional", "00000007", "chained"].pack("H*H*H*a*H*a*H*a*") ) ).to eq packet
      end
    end
  end
end
