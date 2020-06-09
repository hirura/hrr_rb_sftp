RSpec.describe HrrRbSftp::Protocol::Common::DataType::String do
  wljust = Proc.new{ |str, width, padding|
    str_width = str.each_char.to_a.map{|c| c.bytesize == 1 ? 1 : 2}.inject(0, &:+)
    str + padding * [0, width - str_width].max
  }

  wlslice = Proc.new{ |str, width|
    tmp_pos = 0
    tmp_width = 0
    while tmp_pos < str.length
      tmp_width += (str[tmp_pos,1].bytesize == 1 ? 1 : 2)
      break if tmp_width > width
      tmp_pos += 1
    end
    str[0, tmp_pos]
  }

  describe ".encode" do
    context "when arg is string value" do
      context "with length less than or equal to 0xffff_ffff" do

        [
          "",
          "testing",
          "abcdefghijklmnopqrstuvwxyz",
          "ＭＵＬＴＩＢＹＴＥ",
          #"abcd" * (0x3fff_ffff) + "xyz",
        ].each do |str|
          str_len_hex       = "%08x" % str.bytesize
          str_len_hex_array = str_len_hex.each_char.each_slice(2).map(&:join)
          str_hex           = str.unpack("H21")[0]
          str_hex_array     = str_hex[0,20].each_char.each_slice(2).map(&:join) + if str_hex.bytesize > 20 then ["..."] else [] end
          encoded_array     = str_len_hex_array + str_hex_array
          str_width         = str.each_char.to_a.map{|c| c.bytesize == 1 ? 1 : 2}.inject(0, &:+)
          from_str          = wljust.call("\"#{if str_width > 15 then wljust.call(wlslice.call(str, 12) + "...", 12, " ") else str end}\"", 17, " ")
          to_str            = "\"#{encoded_array.join(" ")}\""

          it "encodes #{from_str} to #{to_str}" do
            expect(HrrRbSftp::Protocol::Common::DataType::String.encode str).to eq ([str_len_hex].pack("H*") + [str].pack("a*"))
          end
        end
      end

      context "with length greater than 0xffff_ffff" do
        it "encodes string with length longer than 0xffff_ffff (0xffff_ffff + 1) with error" do
          str_mock = double("str mock with length (0xffff_ffff + 1)")

          expect(str_mock).to receive(:kind_of?).with(::String).and_return(true).once
          expect(str_mock).to receive(:bytesize).with(no_args).and_return(0xffff_ffff + 1).twice

          expect { HrrRbSftp::Protocol::Common::DataType::String.encode str_mock }.to raise_error ArgumentError
        end
      end
    end

    context "when arg is not string value" do
      [
        0,
        false,
        true,
        [],
        {},
        Object,
      ].each do |value|
        value_pretty = value.inspect.ljust(6, " ")

        it "encodes #{value_pretty} with error" do
          expect { HrrRbSftp::Protocol::Common::DataType::String.encode value }.to raise_error ArgumentError
        end
      end
    end
  end

  describe ".decode" do
    [
      "",
      "testing",
      "abcdefghijklmnopqrstuvwxyz",
      "ＭＵＬＴＩＢＹＴＥ",
      #"abcd" * (0x3fff_ffff) + "xyz",
    ].each do |str|
      str_len_hex       = "%08x" % str.bytesize
      str_len_hex_array = str_len_hex.each_char.each_slice(2).map(&:join)
      str_hex           = str.unpack("H21")[0]
      str_hex_array     = str_hex[0,20].each_char.each_slice(2).map(&:join) + if str_hex.bytesize > 20 then ["..."] else [] end
      encoded_array     = str_len_hex_array + str_hex_array
      str_width         = str.each_char.to_a.map{|c| c.bytesize == 1 ? 1 : 2}.inject(0, &:+)
      from_str          = "\"#{encoded_array.join(" ")}\"".ljust(47, " ")
      to_str            = wljust.call("\"#{if str_width > 15 then wljust.call(wlslice.call(str, 12) + "...", 12, " ") else str end}\"", 17, " ")

      it "decodes #{from_str} to #{to_str}" do
        io = StringIO.new ([str_len_hex].pack("H*") + [str].pack("a*")), "r"
        expect(HrrRbSftp::Protocol::Common::DataType::String.decode io).to eq str
      end
    end
  end
end
