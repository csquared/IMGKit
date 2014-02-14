require "spec_helper"

describe IMGKit::Configuration do
  describe "#wkhtmltoimage" do
    context "system version exists" do
      let(:system_path) { "/path/to/wkhtmltoimage\n" }

      before(:each) do
        subject.stub :` => system_path
      end

      context "with Bundler" do
        before(:each) do
          subject.stub :using_bundler? => true
        end

        it "should return the result of `bundle exec which wkhtmltoimage` with whitespace stripped" do
          subject.should_receive(:`).with("bundle exec which wkhtmltoimage")
          subject.wkhtmltoimage.should == system_path.chomp
        end
      end

      context "without Bundler" do
        before(:each) do
          subject.stub :using_bundler? => false
        end

        it "should return the result of `which wkhtmltoimage` with whitespace stripped" do
          subject.should_receive(:`).with("which wkhtmltoimage")
          subject.wkhtmltoimage.should == system_path.chomp
        end
      end
    end

    context "system version does not exist" do
      before(:each) do
        subject.stub :` => "\n"
        subject.stub :using_bundler? => false
      end

      it "should return the fallback path" do
        subject.wkhtmltoimage.should == "/usr/local/bin/wkhtmltoimage"
      end
    end

    context "set explicitly" do
      let(:explicit_path) { "/explicit/path/to/wkhtmltoimage" }

      before(:each) do
        subject.wkhtmltoimage = explicit_path
      end

      it "should not check the system version and return the explicit path" do
        subject.should_not_receive(:`)
        subject.wkhtmltoimage.should == explicit_path
      end
    end
  end
end
