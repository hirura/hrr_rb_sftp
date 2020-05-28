RSpec.describe HrrRbSftp::Loggable do
  context "when initialize method does not initialize internal logger" do
    let(:loggable_instance){
      Class.new{
        include HrrRbSftp::Loggable
      }.new
    }

    describe ".initialize" do
      it "does not initialize @logger" do
        expect(loggable_instance.instance_variable_get("@logger")).to be nil
      end
    end

    describe "#logger" do
      it "returns nil" do
        expect(loggable_instance.logger).to be nil
      end
    end
  end

  context "when initialize method initializes internal logger" do
    let(:internal_logger){
      Class.new{
        def fatal arg; "fatal" + arg + yield; end
        def error arg; "error" + arg + yield; end
        def warn  arg; "warn"  + arg + yield; end
        def info  arg; "info"  + arg + yield; end
        def debug arg; "debug" + arg + yield; end
      }.new
    }

    let(:loggable_instance){
      Class.new{
        include HrrRbSftp::Loggable
        def initialize logger
          self.logger = logger
        end
      }.new(internal_logger)
    }

    let(:log_key){ loggable_instance.class.to_s + "[%x]" % loggable_instance.object_id }

    describe ".initialize" do
      it "initializes @logger" do
        expect(loggable_instance.instance_variable_get("@logger")).to be internal_logger
      end
    end

    describe "#logger" do
      it "returns logger" do
        expect(loggable_instance.logger).to be internal_logger
      end
    end

    describe '#log_fatal' do
      let(:msg){ "msg" }

      it "calls #fatal method of internal logger with log_key progname and message block" do
        expect(loggable_instance.log_fatal { msg }).to eq ("fatal" + log_key + msg)
      end
    end

    describe '#log_error' do
      let(:msg){ "msg" }

      it "calls #error method of internal logger with log_key progname and message block" do
        expect(loggable_instance.log_error { msg }).to eq ("error" + log_key + msg)
      end
    end

    describe '#log_warn' do
      let(:msg){ "msg" }

      it "calls #warn method of internal logger with log_key progname and message block" do
        expect(loggable_instance.log_warn { msg }).to eq ("warn" + log_key + msg)
      end
    end

    describe '#log_info' do
      let(:msg){ "msg" }

      it "calls #info method of internal logger with log_key progname and message block" do
        expect(loggable_instance.log_info { msg }).to eq ("info" + log_key + msg)
      end
    end

    describe '#log_debug' do
      let(:msg){ "msg" }

      it "calls #debug method of internal logger with log_key progname and message block" do
        expect(loggable_instance.log_debug { msg }).to eq ("debug" + log_key + msg)
      end
    end
  end
end
