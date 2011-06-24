require 'spec_helper' 

describe IMGKit do
  context "initialization" do
    it "should accept HTML as the source" do
      imgkit = IMGKit.new('<h1>Oh Hai</h1>')
      imgkit.source.should be_html
      imgkit.source.to_s.should == '<h1>Oh Hai</h1>'
    end
    
    it "should accept a URL as the source" do
      imgkit = IMGKit.new('http://google.com')
      imgkit.source.should be_url
      imgkit.source.to_s.should == 'http://google.com'
    end
    
    it "should accept a File as the source" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      imgkit = IMGKit.new(File.new(file_path))
      imgkit.source.should be_file
      imgkit.source.to_s.should == file_path
    end
    
    it "should provide no default options" do
      imgkit = IMGKit.new('<h1>Oh Hai</h1>')
      imgkit.options.should be_empty
    end
    
=begin
    it "should default to 'UTF-8' encoding" do
      imgkit = IMGKit.new('Captación')
    end
=end
    
    it "should not have any stylesheet by default" do
      imgkit = IMGKit.new('<h1>Oh Hai</h1>')
      imgkit.stylesheets.should be_empty
    end
  end
  
  context "command" do
    it "should contstruct the correct command" do
      imgkit = IMGKit.new('html')
      imgkit.command[0].should include('wkhtmltoimage')
      imgkit.command.should include('-')
    end

    it "should parse the options into a cmd line friedly format" do
      imgkit = IMGKit.new('html', :quality => 75)
      imgkit.command.should include('--quality')
    end
    
    it "will not include default options it is told to omit" do
      imgkit = IMGKit.new('html')
      imgkit = IMGKit.new('html', :disable_smart_shrinking => false)
      imgkit.command.should_not include('--disable-smart-shrinking')
    end
    it "should encapsulate string arguments in quotes" do
      imgkit = IMGKit.new('html', :header_center => "foo [page]")
      imgkit.command[imgkit.command.index('--header-center') + 1].should == 'foo [page]'
    end

    it "should properly handle multi-part arguments" do
      imgkit = IMGKit.new('html', :custom_header => ['User-Agent', 'some user agent'])
      imgkit.command[imgkit.command.index('--custom-header') + 1].should == 'User-Agent'
      imgkit.command[imgkit.command.index('--custom-header') + 2].should == 'some user agent'
    end
    
    it "read the source from stdin if it is html" do
      imgkit = IMGKit.new('html')
      imgkit.command[-2..-1].should == ['-', '-']
    end
    
    it "specify the URL to the source if it is a url" do
      imgkit = IMGKit.new('http://google.com')
      imgkit.command[-2..-1].should == ['http://google.com', '-']
    end
    
    it "should specify the path to the source if it is a file" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      imgkit = IMGKit.new(File.new(file_path))
      imgkit.command[-2..-1].should == [file_path, '-']
    end

    it "should detect special imgkit meta tags" do
      body = %{
        <html>
          <head>
            <meta name="imgkit-page_size" content="Legal"/>
            <meta name="imgkit-orientation" content="Landscape"/>
          </head>
        </html>
      }
      imgkit = IMGKit.new(body)
      imgkit.command[imgkit.command.index('--page-size') + 1].should == 'Legal'
      imgkit.command[imgkit.command.index('--orientation') + 1].should == 'Landscape'
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
      filetype_of(img).should include('JPEG')
    end
    
    it "should generate an Image with a numerical parameter" do
      imgkit = IMGKit.new('html', :quality => 50)
      img = imgkit.to_img
      filetype_of(img).should include('JPEG')
    end
    
    it "should generate an Image with a symbol parameter" do
      imgkit = IMGKit.new('html', :username => 'chris')
      img = imgkit.to_img
      filetype_of(img).should include('JPEG')
    end

    it "should have the stylesheet added to the head if it has one" do
      imgkit = IMGKit.new("<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      imgkit.stylesheets << css
      imgkit.to_img
      imgkit.source.to_s.should include("<style>#{File.read(css)}</style>")
    end

    it "should accept stylesheet as an object which responds to #read" do
      imgkit = IMGKit.new("<html><head></head><body>Hai!</body></html>")
      css = StringIO.new( File.read(File.join(SPEC_ROOT,'fixtures','example.css')) )
      imgkit.stylesheets << css
      imgkit.to_img
      imgkit.source.to_s.should include("<style>#{css.string}</style>")
    end

    it "should prepend style tags if the HTML doesn't have a head tag" do
      imgkit = IMGKit.new("<html><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      imgkit.stylesheets << css
      imgkit.to_img
      imgkit.source.to_s.should include("<style>#{File.read(css)}</style><html>")
    end
    
    it "should throw an error if the source is not html and stylesheets have been added" do
      imgkit = IMGKit.new('http://google.com')
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      imgkit.stylesheets << css
      lambda { imgkit.to_img }.should raise_error(IMGKit::ImproperSourceError)
    end

    it "should throw an error if the wkhtmltoimage command fails" do
                                    #stdin        #stdout       #stderr
      Open3.stub(:popen3).and_yield(StringIO.new, StringIO.new, StringIO.new("This failed, dude"))
      imgkit = IMGKit.new('http://www.example.com')
      lambda { imgkit.to_img }.should raise_error(IMGKit::CommandFailedError)
    end

    context "when there is no format" do
      it "should fallback to jpg" do
        IMGKit.new("Hello, world").to_img.should be_a(:jpg)
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
          IMGKit.new("Oh hai!").to_img.should be_a(:png)
        end
      end
    end

    context "when format = :jpg" do
      it "should create a jpg" do
        IMGKit.new("Hello, world").to_img(:jpg).should be_a(:jpg)
      end
    end

    context "when format is a known format" do
      it "should create an image with that format" do
        IMGKit::KNOWN_FORMATS.each do |format|
          IMGKit.new("Hello, world").to_img(format).should be_a(format)
        end
      end
    end

    context "when format is unknown" do
      it "should raise an UnknownFormatError" do
        lambda { IMGKit.new("Hello, world").to_img(:blah) }.should raise_error(IMGKit::UnknownFormatError)
      end
    end
  end

  context "#to_<known_format>" do
    IMGKit::KNOWN_FORMATS.each do |format|
      describe "#to_#{format}" do
        it "should create a #{format}" do
          IMGKit.new("Hello").send("to_#{format}").should be_a(format)
        end
      end
    end
  end

  context "#to_<unkown_format>" do
    it "should raise and UnknownFormatError" do
      lambda { IMGKit.new("Hello, world").to_blah }.should raise_error(IMGKit::UnknownFormatError)
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
    
    it "should create a file with the result of :to_img  as content" do
      imgkit = IMGKit.new('html', :quality => 50)
      imgkit.expects(:to_img).returns('CONTENT')
      file = imgkit.to_file(@file_path)
      file.should be_instance_of(File)
      File.read(file.path).should == 'CONTENT'
    end

    IMGKit::KNOWN_FORMATS.each do |format|
      it "should use the extension #{format} as the format" do
        @file_path = File.join(SPEC_ROOT,'fixtures',"test.#{format}")
        imgkit = IMGKit.new('html', :quality => 50)
        file = imgkit.to_file(@file_path)
        file.should be_instance_of(File)
        File.open(file.path, "r:ASCII-8BIT") { |f| f.read.should be_a(format) }
      end
    end

    it "should raise UnknownFormatError when format is unknown" do
      kit = IMGKit.new("html")
      lambda { 
        kit.to_file("file.bad_format") 
      }.should raise_error(IMGKit::UnknownFormatError)
    end

    it "should not create the file if format is unknown" do
      kit = IMGKit.new("html")
      kit.to_file("file.bad_format") rescue nil 
      File.exist?("file.bad_format").should be_false
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
      File.exist?(@test_path).should be_false
    end
  end
end
