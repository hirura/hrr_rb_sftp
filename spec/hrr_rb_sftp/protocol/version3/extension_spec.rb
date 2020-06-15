RSpec.describe HrrRbSftp::Protocol::Version3::Extension do
  dummy_class_name = :"Dummy"
  dummy_extension_name = "dummy@dummy.dummy"
  dummy_request_format = {
    :"extended-request" => {
      dummy_extension_name => [
        [String, :"request"],
      ],
    },
  }
  dummy_reply_format = {
    :"extended-reply" => {
      dummy_extension_name => [
        [String, :"reply"],
      ],
    },
  }

  before :all do
    dummy_class = Class.new do |klass|
      klass::EXTENSION_NAME = dummy_extension_name
      klass::REQUEST_FORMAT = dummy_request_format
      klass::REPLY_FORMAT   = dummy_reply_format
    end
    described_class.send(:const_set, dummy_class_name, dummy_class)
  end

  after :all do
    described_class.send(:remove_const, dummy_class_name)
  end

  describe ".conditional_request_format" do
    it "includes REQUEST_FORMAT" do
      expect( described_class.conditional_request_format[:"extended-request"][dummy_extension_name] ).to match_array(dummy_request_format[:"extended-request"][dummy_extension_name])
    end
  end

  describe ".conditional_reply_format" do
    it "includes REPLY_FORMAT" do
      expect( described_class.conditional_reply_format[:"extended-reply"][dummy_extension_name] ).to match_array(dummy_reply_format[:"extended-reply"][dummy_extension_name])
    end
  end
end
