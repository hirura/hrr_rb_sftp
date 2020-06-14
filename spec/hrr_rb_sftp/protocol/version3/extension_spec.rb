RSpec.describe HrrRbSftp::Protocol::Version3::Extension do
  dummy_class_name = :"Dummy"
  dummy_extended_name = "dummy@dummy.dummy"
  dummy_extended_format = {
                            dummy_extended_name => [
                                                     [String, :"oldpath"],
                                                     [String, :"newpath"],
                                                   ],
                          }

  before :all do
    dummy_class = Class.new do |klass|
      klass::EXTENDED_NAME = dummy_extended_name
      klass::EXTENDED_FORMAT = dummy_extended_format
    end
    described_class.send(:const_set, dummy_class_name, dummy_class)
    described_class.instance_variable_set(:"@conditional_format", nil)
  end

  after :all do
    described_class.send(:remove_const, dummy_class_name)
    described_class.instance_variable_set(:"@conditional_format", nil)
  end

  describe ".conditional_format" do
    it "returns #{{:"extended-request" => dummy_extended_format}} Hash" do
      expect( described_class.conditional_format[:"extended-request"] ).to include(dummy_extended_format)
    end
  end
end
