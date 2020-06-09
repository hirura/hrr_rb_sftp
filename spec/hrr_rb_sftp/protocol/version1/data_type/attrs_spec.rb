RSpec.describe HrrRbSftp::Protocol::Version1::DataType::Attrs do
  flag_and_field_list = [
    [described_class::SSH_FILEXFER_ATTR_SIZE,        [:"size"                         ]],
    [described_class::SSH_FILEXFER_ATTR_UIDGID,      [:"uid", :"gid"                  ]],
    [described_class::SSH_FILEXFER_ATTR_PERMISSIONS, [:"permissions"                  ]],
    [described_class::SSH_FILEXFER_ATTR_ACMODTIME,   [:"atime", :"mtime"              ]],
    [described_class::SSH_FILEXFER_ATTR_EXTENDED,    [:"extended-count", :"extensions"]],
  ]

  flag_and_name_list = [
    [described_class::SSH_FILEXFER_ATTR_SIZE,        "SSH_FILEXFER_ATTR_SIZE"       ],
    [described_class::SSH_FILEXFER_ATTR_UIDGID,      "SSH_FILEXFER_ATTR_UIDGID"     ],
    [described_class::SSH_FILEXFER_ATTR_PERMISSIONS, "SSH_FILEXFER_ATTR_PERMISSIONS"],
    [described_class::SSH_FILEXFER_ATTR_ACMODTIME,   "SSH_FILEXFER_ATTR_ACMODTIME"  ],
    [described_class::SSH_FILEXFER_ATTR_EXTENDED,    "SSH_FILEXFER_ATTR_EXTENDED"   ],
  ]

  values = {
    :"size"        => 12345,
    :"uid"         => 1001,
    :"gid"         => 2001,
    :"permissions" => "10644".to_i(8),
    :"atime"       => Time.now.to_i,
    :"mtime"       => Time.now.to_i,
    :"extentions"  => [
      [],
      [{:"extension-name" => "name1", :"extension-data" => "data1"}],
      [{:"extension-name" => "name1", :"extension-data" => "data1"}, {:"extension-name" => "name2", :"extension-data" => "data2"}],
    ],
  }

  describe "::SSH_FILEXFER_ATTR_SIZE" do
    let(:value){ 0x00000001 }

    it "is defined" do
      expect(described_class::SSH_FILEXFER_ATTR_SIZE).to eq value
    end
  end

  describe "::SSH_FILEXFER_ATTR_UIDGID" do
    let(:value){ 0x00000002 }

    it "is defined" do
      expect(described_class::SSH_FILEXFER_ATTR_UIDGID).to eq value
    end
  end

  describe "::SSH_FILEXFER_ATTR_PERMISSIONS" do
    let(:value){ 0x00000004 }

    it "is defined" do
      expect(described_class::SSH_FILEXFER_ATTR_PERMISSIONS).to eq value
    end
  end

  describe "::SSH_FILEXFER_ATTR_ACMODTIME" do
    let(:value){ 0x00000008 }

    it "is defined" do
      expect(described_class::SSH_FILEXFER_ATTR_ACMODTIME).to eq value
    end
  end

  describe "::SSH_FILEXFER_ATTR_EXTENDED" do
    let(:value){ 0x80000000 }

    it "is defined" do
      expect(described_class::SSH_FILEXFER_ATTR_EXTENDED).to eq value
    end
  end

  describe ".encode" do
    (0..(flag_and_field_list.size)).each do |n|
      flag_and_field_list.combination(n).each do |targets|
        context "when arg has #{targets.map{|t| t[1]}.flatten.inspect} fields" do
          flags     = targets.map{|t| t[0]}.inject(0){|f,t| f | t}
          arg_array = [[:"flags", flags]] + targets.reject{|t| t[0] == described_class::SSH_FILEXFER_ATTR_EXTENDED}.map{|t| t[1]}.flatten.map{|k| [k, values[k]]}
          arg       = arg_array.inject(Hash.new){|h,(k,v)| h.merge({k => v})}
          encoded = arg_array.map{ |k, v|
            case k
            when :"flags"       then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"size"        then [v.to_s(16).rjust(16, "0")].pack("H*")
            when :"uid"         then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"gid"         then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"permissions" then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"atime"       then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"mtime"       then [v.to_s(16).rjust(8,  "0")].pack("H*")
            end
          }.join

          if targets.any?{|t| t[0] == described_class::SSH_FILEXFER_ATTR_EXTENDED}
            values[:"extentions"].each do |es|
              encoded_extended_count = [es.size.to_s(16).rjust(8, "0")].pack("H*")
              encoded_extensions = es.map{ |e|
                [e[:"extension-name"], e[:"extension-data"]].map{ |s|
                  [s.bytesize.to_s.rjust(8, "0")].pack("H8") + s
                }.join
              }.join

              context "with #{es.size} extensions" do
                it "encodes as expected" do
                  expect(described_class.encode(arg.merge({:"extensions" => es}))).to eq (encoded + encoded_extended_count + encoded_extensions)
                end
              end
            end
          else
            it "encodes as expected" do
              expect(described_class.encode arg).to eq encoded
            end
          end
        end
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
          expect { described_class.encode value }.to raise_error ArgumentError
        end
      end
    end
  end

  describe ".decode" do
    (0..(flag_and_field_list.size)).each do |n|
      flag_and_field_list.combination(n).each do |targets|
        names = targets.map{|t| flag_and_name_list.find{|f| f[0] == t[0]}[1]}
        context "when flags are #{names.inspect}" do
          flags     = targets.map{|t| t[0]}.inject(0){|f,t| f | t}
          arg_array = [[:"flags", flags]] + targets.reject{|t| t[0] == described_class::SSH_FILEXFER_ATTR_EXTENDED}.map{|t| t[1]}.flatten.map{|k| [k, values[k]]}
          arg       = arg_array.inject(Hash.new){|h,(k,v)| h.merge({k => v})}
          encoded = arg_array.map{ |k, v|
            case k
            when :"flags"       then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"size"        then [v.to_s(16).rjust(16, "0")].pack("H*")
            when :"uid"         then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"gid"         then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"permissions" then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"atime"       then [v.to_s(16).rjust(8,  "0")].pack("H*")
            when :"mtime"       then [v.to_s(16).rjust(8,  "0")].pack("H*")
            end
          }.join

          if targets.any?{|t| t[0] == described_class::SSH_FILEXFER_ATTR_EXTENDED}
            values[:"extentions"].each do |es|
              encoded_extended_count = [es.size.to_s(16).rjust(8, "0")].pack("H*")
              encoded_extensions = es.map{ |e|
                [e[:"extension-name"], e[:"extension-data"]].map{ |s|
                  [s.bytesize.to_s.rjust(8, "0")].pack("H8") + s
                }.join
              }.join

              context "with #{es.size} extensions" do
                it "decodes as expected" do
                  io = StringIO.new (encoded + encoded_extended_count + encoded_extensions), "r"
                  expect(described_class.decode io).to eq arg.reject{|k,v| k == :"flags"}.merge({:"extensions" => es})
                end
              end
            end
          else
            it "decodes as expected" do
              io = StringIO.new encoded, "r"
              expect(described_class.decode io).to eq arg.reject{|k,v| k == :"flags"}
            end
          end
        end
      end
    end
  end
end
