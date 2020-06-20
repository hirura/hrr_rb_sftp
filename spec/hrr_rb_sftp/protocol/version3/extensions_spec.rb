RSpec.describe HrrRbSftp::Protocol::Version3::Extensions do
  dummy_class_name = :"Dummy"
  dummy_extension_name = "dummy@dummy.dummy"
  dummy_extension_data = "1"
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

  let(:context){
    {}
  }

  before :all do
    dummy_class = Class.new(described_class::Extension) do |klass|
      klass::EXTENSION_NAME = dummy_extension_name
      klass::EXTENSION_DATA = dummy_extension_data
      klass::REQUEST_FORMAT = dummy_request_format
      klass::REPLY_FORMAT   = dummy_reply_format
      def respond_to request
        "dummy"
      end
    end
    described_class.send(:const_set, dummy_class_name, dummy_class)
  end

  after :all do
    described_class.send(:remove_const, dummy_class_name)
  end

  describe ".extension_classes" do
    it "includes classes that has EXTENSION_NAME constant" do
      expect( described_class.extension_classes.all?{|c| c.const_defined?(:EXTENSION_NAME)} ).to be true
    end
  end

  describe ".extension_pairs" do
    it "returns a list of extension-pair of EXTENSION_NAME and EXTENSION_DATA" do
      expect( described_class.extension_pairs ).to include({:"extension-name" => dummy_extension_name, :"extension-data" => dummy_extension_data})
    end
  end

  describe "#respond_to?" do
    let(:request){
      {
        :"extended-request" => extended_request,
      }
    }

    context "when request argment is valid" do
      let(:extended_request){ dummy_extension_name }

      it "returns true" do
        expect( described_class.new(context).respond_to?(request) ).to be true
      end
    end

    context "when request argment is not valid" do
      let(:extended_request){ "undefined" }

      it "returns false" do
        expect( described_class.new(context).respond_to?(request) ).to be false
      end
    end
  end

  describe "#respond_to" do
    let(:request){
      {
        :"extended-request" => extended_request,
      }
    }
    let(:extended_request){ dummy_extension_name }

    it "returns response" do
      expect( described_class.new(context).respond_to(request) ).to eq "dummy"
    end
  end

  describe "#conditional_request_format" do
    it "includes REQUEST_FORMAT" do
      expect( described_class.new(context).conditional_request_format[:"extended-request"] ).to include(dummy_request_format[:"extended-request"])
    end
  end

  describe "#conditional_reply_format" do
    it "includes REPLY_FORMAT" do
      expect( described_class.new(context).conditional_reply_format[:"extended-reply"] ).to include(dummy_reply_format[:"extended-reply"])
    end
  end
end
