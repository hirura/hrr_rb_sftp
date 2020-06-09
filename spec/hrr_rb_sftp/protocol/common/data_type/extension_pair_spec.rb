RSpec.describe HrrRbSftp::Protocol::Common::DataType::ExtensionPair do
  describe ".encode" do
    context "when arg is an Array of two Strings" do
      arg = {:"extension-name" => "name", :"extension-data" => "data"}
      encoded = [arg[:"extension-name"], arg[:"extension-data"]].map{ |e|
        [e.bytesize.to_s.rjust(8, "0")].pack("H8") + e
      }.join
      encoded_pretty = [arg[:"extension-name"], arg[:"extension-data"]].map{ |e|
        [
          e.bytesize.to_s.rjust(8, "0").each_char.each_slice(2).map(&:join).join(" "),
          e.each_char.to_a.join(" ")
        ].join(" ")
      }.join(" ")

      it "encodes #{arg.inspect} to #{"\"%s\"" % encoded_pretty}" do
        expect(HrrRbSftp::Protocol::Common::DataType::ExtensionPair.encode arg).to eq encoded
      end
    end

    context "when arg is not a Hash value" do
      [
        0,
        false,
        true,
        "",
        [],
        Object,
      ].each do |value|
        it "encodes #{value.inspect.ljust(6, " ")} raises ArgumentError" do
          expect { HrrRbSftp::Protocol::Common::DataType::ExtensionPair.encode value }.to raise_error ArgumentError
        end
      end
    end
  end

  describe ".decode" do
    arg = {:"extension-name" => "name", :"extension-data" => "data"}
    encoded = [arg[:"extension-name"], arg[:"extension-data"]].map{ |e|
      [e.bytesize.to_s.rjust(8, "0")].pack("H8") + e
    }.join
    encoded_pretty = [arg[:"extension-name"], arg[:"extension-data"]].map{ |e|
      [
        e.bytesize.to_s.rjust(8, "0").each_char.each_slice(2).map(&:join).join(" "),
        e.each_char.to_a.join(" ")
      ].join(" ")
    }.join(" ")

    it "decodes #{("\"%s\"" % encoded_pretty)} to #{arg.inspect}" do
      io = StringIO.new encoded, "r"
      expect(HrrRbSftp::Protocol::Common::DataType::ExtensionPair.decode io).to eq arg
    end
  end
end
