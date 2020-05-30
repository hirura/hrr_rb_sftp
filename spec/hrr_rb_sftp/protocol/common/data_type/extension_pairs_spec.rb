require "stringio"

RSpec.describe HrrRbSftp::Protocol::Common::DataType::ExtensionPairs do
  describe ".encode" do
    [
      [],
      [{:"extension-name" => "name1", :"extension-data" => "data1"}],
      [{:"extension-name" => "name1", :"extension-data" => "data1"}, {:"extension-name" => "name2", :"extension-data" => "data2"}],
    ].each do |arg|
      context "when arg Array size is #{arg.size}" do
        encoded = arg.map{ |pair|
          [pair[:"extension-name"], pair[:"extension-data"]].map{ |e|
            [e.length.to_s.rjust(8, "0")].pack("H8") + e
          }
        }.join
        encoded_pretty = arg.map{ |pair|
          [pair[:"extension-name"], pair[:"extension-data"]].map{ |e|
            [
              e.length.to_s.rjust(8, "0").each_char.each_slice(2).map(&:join).join(" "),
              e.each_char.to_a.join(" ")
            ].join(" ")
          }.join(" ")
        }.join(" ")

        it "encodes #{arg.inspect} to #{"\"%s\"" % encoded_pretty}" do
          expect(HrrRbSftp::Protocol::Common::DataType::ExtensionPairs.encode arg).to eq encoded
        end
      end
    end

    context "when arg is not an Array value" do
      [
        0,
        false,
        true,
        "",
        {},
        Object,
      ].each do |value|
        it "encodes #{value.inspect.ljust(6, " ")} raises ArgumentError" do
          expect { HrrRbSftp::Protocol::Common::DataType::ExtensionPairs.encode value }.to raise_error ArgumentError
        end
      end
    end
  end

  describe ".decode" do
    [
      [],
      [{:"extension-name" => "name1", :"extension-data" => "data1"}],
      [{:"extension-name" => "name1", :"extension-data" => "data1"}, {:"extension-name" => "name2", :"extension-data" => "data2"}],
    ].each do |arg|
      context "when the number of pairs is #{arg.size}" do
        encoded = arg.map{ |pair|
          [pair[:"extension-name"], pair[:"extension-data"]].map{ |e|
            [e.length.to_s.rjust(8, "0")].pack("H8") + e
          }
        }.join
        encoded_pretty = arg.map{ |pair|
          [pair[:"extension-name"], pair[:"extension-data"]].map{ |e|
            [
              e.length.to_s.rjust(8, "0").each_char.each_slice(2).map(&:join).join(" "),
              e.each_char.to_a.join(" ")
            ].join(" ")
          }.join(" ")
        }.join(" ")

        it "decodes #{("\"%s\"" % encoded_pretty)} to #{arg.inspect}" do
          io = StringIO.new encoded, "r"
          expect(HrrRbSftp::Protocol::Common::DataType::ExtensionPairs.decode io).to eq arg
        end
      end
    end
  end
end
