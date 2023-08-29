require 'spec_helper'

describe IMGKit do
  context "initialization" do
    it "should accept HTML as the source" do
      imgkit = IMGKit.new('<h1>Oh Hai</h1>')
      expect(imgkit.source).to be_html
      expect(imgkit.source.to_s).to eq '<h1>Oh Hai</h1>'
    end

    it "should accept a URL as the source" do
      imgkit = IMGKit.new('http://google.com')
      expect(imgkit.source).to be_url
      expect(imgkit.source.to_s).to eq 'http://google.com'
    end

    it "should accept a File as the source" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      imgkit = IMGKit.new(File.new(file_path))
      expect(imgkit.source).to be_file
      expect(imgkit.source.to_s).to eq file_path
    end

    it "should provide no default options" do
    end

    it "should set a default height" do
      imgkit = IMGKit.new('<h1>Oh Hai</h1>')
      expect(imgkit.options.length).to be 1
      expect(imgkit.options[:height]).to be 0
    end


=begin
    it "should default to 'UTF-8' encoding" do
      imgkit = IMGKit.new('Captación')
    end
=end

    it "should not have any stylesheet by default" do
      imgkit = IMGKit.new('<h1>Oh Hai</h1>')
      expect(imgkit.stylesheets).to be_empty
    end
  end

  context "command" do
    it "should contstruct the correct command" do
      imgkit = IMGKit.new('html')
      expect(imgkit.command[0]).to include('wkhtmltoimage')
      expect(imgkit.command).to include('-')
    end

    it "should parse the options into a cmd line friedly format" do
      imgkit = IMGKit.new('html', :quality => 75)
      expect(imgkit.command).to include('--quality')
    end

    it "will not include default options it is told to omit" do
      imgkit = IMGKit.new('html')
      imgkit = IMGKit.new('html', :disable_smart_shrinking => false)
      expect(imgkit.command).to_not include('--disable-smart-shrinking')
    end
    it "should encapsulate string arguments in quotes" do
      imgkit = IMGKit.new('html', :header_center => "foo [page]")
      expect(imgkit.command[imgkit.command.index('--header-center') + 1]).to eq 'foo [page]'
    end

    it "should properly handle multi-part arguments" do
      imgkit = IMGKit.new('html', :custom_header => ['User-Agent', 'some user agent'])
      expect(imgkit.command[imgkit.command.index('--custom-header') + 1]).to eq 'User-Agent'
      expect(imgkit.command[imgkit.command.index('--custom-header') + 2]).to eq 'some user agent'
    end

    it "read the source from stdin if it is html" do
      imgkit = IMGKit.new('html')
      expect(imgkit.command[-2..-1]).to eq ['-', '-']
    end

    it "specify the URL to the source if it is a url" do
      imgkit = IMGKit.new('http://google.com')
      expect(imgkit.command[-2..-1]).to eq ['http://google.com', '-']
    end

    it "should specify the path to the source if it is a file" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      imgkit = IMGKit.new(File.new(file_path))
      expect(imgkit.command[-2..-1]).to eq [file_path, '-']
    end

    it "should detect special imgkit meta tags" do
      body = %{
        <html>
          <head>
            <meta name="imgkit-page_size" content="Legal"/>
            <meta name="imgkit-orientation" content="Landscape"/>
            <meta name="imgkit-crop-h" content="900"/>
          </head>
        </html>
      }
      imgkit = IMGKit.new(body)
      expect(imgkit.command[imgkit.command.index('--page-size') + 1]).to eq 'Legal'
      expect(imgkit.command[imgkit.command.index('--orientation') + 1]).to eq 'Landscape'
      expect(imgkit.command[imgkit.command.index('--crop-h') + 1]).to eq '900'
    end
  end

  context "#to_img(format = nil)" do
    def filetype_of(img)
      result = nil
      tmpfile = Tempfile.new('imgkit')
      File.open(tmpfile.path, 'w') { |f| f << img }
      result = `file #{tmpfile.path}`
      tmpfile.unlink()
      result
    end

    it "should generate a IMG of the HTML" do
      imgkit = IMGKit.new('html')
      img = imgkit.to_img
      expect(filetype_of(img)).to include('JPEG')
    end

    it "should generate an Image with a numerical parameter" do
      imgkit = IMGKit.new('html', :quality => 50)
      img = imgkit.to_img
      expect(filetype_of(img)).to include('JPEG')
    end

    it "should generate an Image with a symbol parameter" do
      imgkit = IMGKit.new('html', :username => 'chris')
      img = imgkit.to_img
      expect(filetype_of(img)).to include('JPEG')
    end

    it "should have the stylesheet added to the head if it has one" do
      imgkit = IMGKit.new("<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      imgkit.stylesheets << css
      imgkit.to_img
      expect(imgkit.source.to_s).to include("<style>#{File.read(css)}</style>")
    end

    it "should accept stylesheet as an object which responds to #read" do
      imgkit = IMGKit.new("<html><head></head><body>Hai!</body></html>")
      css = StringIO.new( File.read(File.join(SPEC_ROOT,'fixtures','example.css')) )
      imgkit.stylesheets << css
      imgkit.to_img
      expect(imgkit.source.to_s).to include("<style>#{css.string}</style>")
    end

    it "should prepend style tags if the HTML doesn't have a head tag" do
      imgkit = IMGKit.new("<html><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      imgkit.stylesheets << css
      imgkit.to_img
      expect(imgkit.source.to_s).to include("<style>#{File.read(css)}</style><html>")
    end

    it "should throw an error if the source is not html and stylesheets have been added" do
      imgkit = IMGKit.new('http://google.com')
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      imgkit.stylesheets << css
      expect { imgkit.to_img }.to raise_error(IMGKit::ImproperSourceError)
    end

    it "should have the script added to the head if it has one" do
      imgkit = IMGKit.new("<html><head></head><body>Hai!</body></html>")
      js = File.join(SPEC_ROOT,'fixtures','example.js')
      imgkit.javascripts << js
      imgkit.to_img
      expect(imgkit.source.to_s).to include("<script src=\"#{js}\" type=\"text/javascript\"></script>")
    end

    it "should accept script as an object which responds to #read" do
      imgkit = IMGKit.new("<html><head></head><body>Hai!</body></html>")
      js = StringIO.new( File.read(File.join(SPEC_ROOT,'fixtures','example.js')) )
      imgkit.javascripts << js
      imgkit.to_img
      expect(imgkit.source.to_s).to include("<script>#{js.string}</script>")
    end

    it "should prepend script tags if the HTML doesn't have a head tag" do
      imgkit = IMGKit.new("<html><body>Hai!</body></html>")
      js = File.join(SPEC_ROOT,'fixtures','example.js')
      imgkit.javascripts << js
      imgkit.to_img
      expect(imgkit.source.to_s).to include("<script src=\"#{js}\" type=\"text/javascript\"></script>")
    end

    it "should throw an error if the source is not html and script have been added" do
      imgkit = IMGKit.new('http://google.com')
      js = File.join(SPEC_ROOT,'fixtures','example.js')
      imgkit.javascripts << js
      expect { imgkit.to_img }.to raise_error(IMGKit::ImproperSourceError)
    end

    def set_wkhtmltoimage_binary(binary)
      spec_dir = File.dirname(__FILE__)
      expect(IMGKit.configuration).to receive(:wkhtmltoimage).at_least(1).times.and_return(File.join(spec_dir, binary))
    end

    it "should throw an error if the wkhtmltoimage command fails" do
      set_wkhtmltoimage_binary 'error_binary'
      imgkit = IMGKit.new('http://www.example.com')
      expect { imgkit.to_img }.to raise_error(IMGKit::CommandFailedError)
    end

    it "should be able to handle lots of error output" do
      set_wkhtmltoimage_binary 'warning_binary'
      imgkit = IMGKit.new("<html><body>Hai!</body></html>")
      expect(imgkit.to_img).to eq "result\n"
    end

    context "when there is no format" do
      it "should fallback to jpg" do
        expect(IMGKit.new("Hello, world").to_img).to be_a(:jpg)
      end

      context "when a default_format has been configured" do
        before do
          IMGKit.configure do |config|
            config.default_format = :png
          end
        end

        after do
          IMGKit.configure do |config|
            config.default_format = :jpg
          end
        end

        it "should use the configured format" do
          expect(IMGKit.new("Oh hai!").to_img).to be_a(:png)
        end
      end
    end

    context "when format = :jpg" do
      it "should create a jpg" do
        expect(IMGKit.new("Hello, world").to_img(:jpg)).to be_a(:jpg)
      end
    end

    context "when format is a known format" do
      it "should create an image with that format" do
        IMGKit::KNOWN_FORMATS.each do |format|
          expect(IMGKit.new("Hello, world").to_img(format)).to be_a(format)
        end
      end
    end

    context "when format is unknown" do
      it "should raise an UnknownFormatError" do
        expect { IMGKit.new("Hello, world").to_img(:blah) }.to raise_error(IMGKit::UnknownFormatError)
      end
    end
  end

  context "#to_<known_format>" do
    IMGKit::KNOWN_FORMATS.each do |format|
      describe "#to_#{format}" do
        it "should create a #{format}" do
          expect(IMGKit.new("Hello").send("to_#{format}")).to be_a(format)
        end
      end
    end
  end

  context "#to_<unkown_format>" do
    it "should raise and UnknownFormatError" do
      expect { IMGKit.new("Hello, world").to_blah }.to raise_error(IMGKit::UnknownFormatError)
    end
  end

  context "#to_file" do
    before do
      @file_path = File.join(SPEC_ROOT,'fixtures','test.jpg')
      File.delete(@file_path) if File.exist?(@file_path)
    end

    after do
      File.delete(@file_path) if File.exist?(@file_path)
    end

    it "should create a binary file" do
      imgkit = IMGKit.new('html', :quality => 50)
      file = imgkit.to_file(@file_path)
      expect(file).to be_instance_of(File)
      expect(File.exist?(file.path)).to be true
    end

    IMGKit::KNOWN_FORMATS.each do |format|
      it "should use the extension #{format} as the format" do
        @file_path = File.join(SPEC_ROOT,'fixtures',"test.#{format}")
        imgkit = IMGKit.new('html', :quality => 50)
        file = imgkit.to_file(@file_path)
        expect(file).to be_instance_of(File)
        File.open(file.path, "r:ASCII-8BIT") { |f| expect(f.read).to be_a(format) }
      end
    end

    it "should raise UnknownFormatError when format is unknown" do
      kit = IMGKit.new("html")
      expect { kit.to_file("file.bad_format") }.to raise_error(IMGKit::UnknownFormatError)
    end

    it "should not create the file if format is unknown" do
      kit = IMGKit.new("html")
      kit.to_file("file.bad_format") rescue nil
      expect(File.exist?("file.bad_format")).to be false
    end
  end

  context "security" do
    before do
      @test_path = File.join(SPEC_ROOT,'fixtures','security-oops')
      File.delete(@test_path) if File.exist?(@test_path)
    end

    after do
      File.delete(@test_path) if File.exist?(@test_path)
    end

    it "should not allow shell injection in options" do
      imgkit = IMGKit.new('html', :password => "blah\"; touch #{@test_path} #")
      imgkit.to_img
      expect(File.exist?(@test_path)).to be false
    end
  end
end
