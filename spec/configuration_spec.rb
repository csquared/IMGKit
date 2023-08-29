require "spec_helper"

describe IMGKit::Configuration do
  describe "#wkhtmltoimage" do
    context "system version exists" do
      let(:system_path) { "/path/to/wkhtmltoimage\n" }
      let(:system_path_with_bundler_warning) { "`/` is not writable.\nBundler will use `/tmp/bundler/home/unknown' as your home directory temporarily.\n/path/to/wkhtmltoimage\n" }

      before(:each) do
        allow(IO).to receive(:popen).and_return(double(read: system_path))
      end

      context "with Bundler" do
        before(:each) do
          allow(subject).to receive(:using_bundler?).and_return(true)
        end

        it "should return the result of `bundle exec which wkhtmltoimage` with whitespace stripped" do
          expect(IO).to receive(:popen).with(%w(bundle exec which wkhtmltoimage))
          expect(subject.wkhtmltoimage).to eq system_path.chomp
        end

        context "with warning" do
          before(:each) do
            allow(IO).to receive(:popen).and_return(double(read: system_path_with_bundler_warning))
          end

          it "should return the result of `bundle exec which wkhtmltoimage` with warning stripped" do
            expect(IO).to receive(:popen).with(%w(bundle exec which wkhtmltoimage))
            expect(subject.wkhtmltoimage).to eq system_path.chomp
          end
        end
      end

      context "without Bundler" do
        before(:each) do
          allow(subject).to receive(:using_bundler?).and_return(false)
        end

        it "should return the result of `which wkhtmltoimage` with whitespace stripped" do
          allow(IO).to receive(:popen).with(%w("which wkhtmltoimage))
          expect(subject.wkhtmltoimage).to eq system_path.chomp
        end
      end
    end

    context "system version does not exist" do
      before(:each) do
        allow(IO).to receive(:popen).and_return(double(read: "\n"))
        allow(subject).to receive(:using_bundler?).and_return(false)
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
        expect(IO).to_not receive(:popen)
        expect(subject.wkhtmltoimage).to eq explicit_path
      end
    end
  end
end
