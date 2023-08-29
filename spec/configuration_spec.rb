require "spec_helper"

describe IMGKit::Configuration do
  describe "#wkhtmltoimage" do
    context "system version exists" do
      let(:system_path) { "/path/to/wkhtmltoimage\n" }
      let(:system_path_with_bundler_warning) { "`/` is not writable.\nBundler will use `/tmp/bundler/home/unknown' as your home directory temporarily.\n/path/to/wkhtmltoimage\n" }

      before(:each) do
        subject.stub :` => system_path
      end

      context "with Bundler" do
        before(:each) do
          subject.stub :using_bundler? => true
        end

        it "should return the result of `bundle exec which wkhtmltoimage` with whitespace stripped" do
          expect(subject).to receive(:`).with("bundle exec which wkhtmltoimage")
          expect(subject.wkhtmltoimage).to eq system_path.chomp
        end

        context "with warning" do
          before(:each) do
            subject.stub :` => system_path_with_bundler_warning
          end

          it "should return the result of `bundle exec which wkhtmltoimage` with warning stripped" do
            expect(subject).to receive(:`).with("bundle exec which wkhtmltoimage")
            expect(subject.wkhtmltoimage).to eq system_path.chomp
          end
        end
      end

      context "without Bundler" do
        before(:each) do
          subject.stub :using_bundler? => false
        end

        it "should return the result of `which wkhtmltoimage` with whitespace stripped" do
          expect(subject).to receive(:`).with("which wkhtmltoimage")
          expect(subject.wkhtmltoimage).to eq system_path.chomp
        end
      end
    end

    context "system version does not exist" do
      before(:each) do
        subject.stub :` => "\n"
        subject.stub :using_bundler? => false
      end

      it "should return the fallback path" do
        expect(subject.wkhtmltoimage).to eq "/usr/local/bin/wkhtmltoimage"
      end
    end

    context "set explicitly" do
      let(:explicit_path) { "/explicit/path/to/wkhtmltoimage" }

      before(:each) do
        subject.wkhtmltoimage = explicit_path
      end

      it "should not check the system version and return the explicit path" do
        expect(subject).to_not receive(:`)
        expect(subject.wkhtmltoimage).to eq explicit_path
      end
    end
  end
end
