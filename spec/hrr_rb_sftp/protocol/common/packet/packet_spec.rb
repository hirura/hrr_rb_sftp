RSpec.describe HrrRbSftp::Protocol::Common::Packets::Packet do
  context "when subclass does not have CONDITIONAL_FORMAT" do
    let(:subclass){
      Class.new(described_class) do |klass|
        klass::TYPE = 255
        klass::FORMAT = [
          [HrrRbSftp::Protocol::Common::DataTypes::Byte,   :"type"],
          [HrrRbSftp::Protocol::Common::DataTypes::Uint32, :"request-id"],
          [HrrRbSftp::Protocol::Common::DataTypes::String, :"data"      ],
        ]
      end
    }

    describe ".new" do
      it "does not take arguments" do
        expect{ subclass.new }.not_to raise_error
      end
    end

    describe "#encode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing"}

      context "when each arg is acceptable by data_type" do
        it "encodes #{packet.inspect} to \"FF 00 00 00 7B 00 00 00 07 t e s t i n g\"" do
          expect( subclass.new.encode( packet ) ).to eq( ["FF", "0000007B", "00000007", "testing"].pack("H*H*H*a*") )
        end
      end

      context "when an arg is not acceptable by data_type" do
        it "raises an error" do
          expect { subclass.new.encode( {:"type" => 255, :"request-id" => 123, :"data" => nil} ) }.to raise_error ArgumentError
        end
      end
    end

    describe "#decode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing"}

      it "decodes \"FF 00 00 00 7B 00 00 00 07 t e s t i n g\" to #{packet.inspect}" do
        expect( subclass.new.decode( ["FF", "0000007B", "00000007", "testing"].pack("H*H*H*a*") ) ).to eq packet
      end
    end
  end

  context "when subclass has CONDITIONAL_FORMAT" do
    let(:subclass){
      Class.new(described_class) do |klass|
        klass::TYPE = 255
        klass::FORMAT = [
          [HrrRbSftp::Protocol::Common::DataTypes::Byte,   :"type"],
          [HrrRbSftp::Protocol::Common::DataTypes::Uint32, :"request-id"],
          [HrrRbSftp::Protocol::Common::DataTypes::String, :"data"      ],
        ]
        klass::TESTING_FORMAT = [
          [HrrRbSftp::Protocol::Common::DataTypes::String, :"testing data"],
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
        expect{ subclass.new }.not_to raise_error
      end
    end

    describe "#encode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional"}

      context "when each arg is acceptable by data_type" do
        it "encodes #{packet.inspect} to \"FF 00 00 00 7B 00 00 00 07 t e s t i n g 00 00 00 0B c o n d i t i o n a l\"" do
          expect( subclass.new.encode( packet ) ).to eq( ["FF", "0000007B", "00000007", "testing", "0000000B", "conditional"].pack("H*H*H*a*H*a*") )
        end
      end

      context "when an arg is not acceptable by data_type" do
        it "raises an error" do
          expect { subclass.new.encode( {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => nil} ) }.to raise_error ArgumentError
        end
      end
    end

    describe "#decode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional"}

      it "decodes \"FF 00 00 00 7B 00 00 00 07 t e s t i n g 00 00 00 0B c o n d i t i o n a l\" to #{packet.inspect}" do
        expect( subclass.new.decode( ["FF", "0000007B", "00000007", "testing", "0000000B", "conditional"].pack("H*H*H*a*H*a*") ) ).to eq packet
      end
    end
  end

  context "when subclass has chained CONDITIONAL_FORMAT" do
    let(:subclass){
      Class.new(described_class) do |klass|
        klass::TYPE = 255
        klass::FORMAT = [
          [HrrRbSftp::Protocol::Common::DataTypes::Byte,   :"type"],
          [HrrRbSftp::Protocol::Common::DataTypes::Uint32, :"request-id"],
          [HrrRbSftp::Protocol::Common::DataTypes::String, :"data"      ],
        ]
        klass::TESTING_FORMAT = [
          [HrrRbSftp::Protocol::Common::DataTypes::String, :"testing data"],
        ]
        klass::CHAINED_FORMAT = [
          [HrrRbSftp::Protocol::Common::DataTypes::String, :"chained data"],
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
        expect{ subclass.new }.not_to raise_error
      end
    end

    describe "#encode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional", :"chained data" => "chained"}

      context "when each arg is acceptable by data_type" do
        it "encodes #{packet.inspect} to \"FF 00 00 00 7B 00 00 00 07 t e s t i n g 00 00 00 0B c o n d i t i o n a l 00 00 00 07 c h a i n e d\"" do
          expect( subclass.new.encode( packet ) ).to eq( ["FF", "0000007B", "00000007", "testing", "0000000B", "conditional", "00000007", "chained"].pack("H*H*H*a*H*a*H*a*") )
        end
      end

      context "when an arg is not acceptable by data_type" do
        it "raises an error" do
          expect { subclass.new.encode( {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional", :"chained data" => nil} ) }.to raise_error ArgumentError
        end
      end
    end

    describe "#decode" do
      packet = {:"type" => 255, :"request-id" => 123, :"data" => "testing", :"testing data" => "conditional", :"chained data" => "chained"}

      it "decodes \"FF 00 00 00 7B 00 00 00 07 t e s t i n g 00 00 00 0B c o n d i t i o n a l 00 00 00 07 c h a i n e d\" to #{packet.inspect}" do
        expect( subclass.new.decode( ["FF", "0000007B", "00000007", "testing", "0000000B", "conditional", "00000007", "chained"].pack("H*H*H*a*H*a*H*a*") ) ).to eq packet
      end
    end
  end

  context "when subclass has CONDITIONAL_FORMAT that requires complementary packet" do
    let(:subclass){
      Class.new(described_class) do |klass|
        klass::TYPE = 255
        klass::FORMAT = [
          [HrrRbSftp::Protocol::Common::DataTypes::Byte,   :"type"],
          [HrrRbSftp::Protocol::Common::DataTypes::Uint32, :"request-id"],
        ]
        klass::HIDDEN_FORMAT = [
          [HrrRbSftp::Protocol::Common::DataTypes::String, :"hidden data"],
        ]
        klass::CONDITIONAL_FORMAT = {
          :"require hidden" => {
            true => klass::HIDDEN_FORMAT,
          },
        }
      end
    }

    describe ".new" do
      it "does not take arguments" do
        expect{ subclass.new }.not_to raise_error
      end
    end

    describe "#decode" do
      packet = {:"type" => 255, :"request-id" => 123}

      it "decodes \"FF 00 00 00 7B 00 00 00 0B c o n d i t i o n a l\" with complementary message #{{:"require hidden" => true}.inspect} to #{{:"type" => 255, :"request-id" => 123, :"hidden data" => "conditional"}.inspect}" do
        expect( subclass.new.decode( ["FF", "0000007B", "0000000B", "conditional"].pack("H*H*H*a*"), {:"require hidden" => true} ) ).to eq( {:"type" => 255, :"request-id" => 123, :"hidden data" => "conditional"} )
      end
    end
  end
end
