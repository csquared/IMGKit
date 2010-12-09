require 'spec_helper'

describe IMGKit do
  
  context "initialization" do
    it "should accept HTML as the source" do
      pdfkit = IMGKit.new('<h1>Oh Hai</h1>')
      pdfkit.source.should be_html
      pdfkit.source.to_s.should == '<h1>Oh Hai</h1>'
    end
    
    it "should accept a URL as the source" do
      pdfkit = IMGKit.new('http://google.com')
      pdfkit.source.should be_url
      pdfkit.source.to_s.should == 'http://google.com'
    end
    
    it "should accept a File as the source" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = IMGKit.new(File.new(file_path))
      pdfkit.source.should be_file
      pdfkit.source.to_s.should == file_path
    end
    
    it "should parse the options into a cmd line friedly format" do
      pdfkit = IMGKit.new('html', :page_size => 'Letter')
      pdfkit.options.should have_key('--page-size')
    end
    
    it "should provide no default options" do
      pdfkit = IMGKit.new('<h1>Oh Hai</h1>')
      pdfkit.options.should be_empty
    end
    
    it "should default to 'UTF-8' encoding" do
      pdfkit = IMGKit.new('Captación')
    end
    
    it "should not have any stylesheedt by default" do
      pdfkit = IMGKit.new('<h1>Oh Hai</h1>')
      pdfkit.stylesheets.should be_empty
    end
  end
  
  context "command" do
    it "should contstruct the correct command" do
      pdfkit = IMGKit.new('html')
      pdfkit.command[0].should include('wkhtmltoimage')
      pdfkit.command.should include('-')
    end
    
    it "will not include default options it is told to omit" do
      pdfkit = IMGKit.new('html')
      pdfkit.command.should include('--disable-smart-shrinking')
      pdfkit = IMGKit.new('html', :disable_smart_shrinking => false)
      pdfkit.command.should_not include('--disable-smart-shrinking')
    end
    
    it "should encapsulate string arguments in quotes" do
      pdfkit = IMGKit.new('html', :header_center => "foo [page]")
      pdfkit.command[pdfkit.command.index('--header-center') + 1].should == 'foo [page]'
    end
    
    it "read the source from stdin if it is html" do
      pdfkit = IMGKit.new('html')
      pdfkit.command[-2..-1].should == ['-', '-']
    end
    
    it "specify the URL to the source if it is a url" do
      pdfkit = IMGKit.new('http://google.com')
      pdfkit.command[-2..-1].should == ['http://google.com', '-']
    end
    
    it "should specify the path to the source if it is a file" do
      file_path = File.join(SPEC_ROOT,'fixtures','example.html')
      pdfkit = IMGKit.new(File.new(file_path))
      pdfkit.command[-2..-1].should == [file_path, '-']
    end

    it "should detect special pdfkit meta tags" do
      body = %{
        <html>
          <head>
            <meta name="pdfkit-page_size" content="Legal"/>
            <meta name="pdfkit-orientation" content="Landscape"/>
          </head>
        </html>
      }
      pdfkit = IMGKit.new(body)
      pdfkit.command[pdfkit.command.index('--page-size') + 1].should == 'Legal'
      pdfkit.command[pdfkit.command.index('--orientation') + 1].should == 'Landscape'
    end
  end
  
  context "#to_img" do
    it "should generate a IMG of the HTML" do
      pending
      pdfkit = IMGKit.new('html', :page_size => 'Letter')
      pdf = pdfkit.to_pdf
      pdf[0...4].should == "%PDF" # PDF Signature at beginning of file
    end
    
    it "should generate a PDF with a numerical parameter" do
      pending
      pdfkit = IMGKit.new('html', :header_spacing => 1)
      pdf = pdfkit.to_pdf
      pdf[0...4].should == "%PDF" # PDF Signature at beginning of file
    end
    
    it "should generate a PDF with a symbol parameter" do
      pdfkit = IMGKit.new('html', :page_size => :Letter)
      pdf = pdfkit.to_pdf
      pdf[0...4].should == "%PDF" # PDF Signature at beginning of file
    end
    
    it "should have the stylesheet added to the head if it has one" do
      pdfkit = IMGKit.new("<html><head></head><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.source.to_s.should include("<style>#{File.read(css)}</style>")
    end
    
    it "should prepend style tags if the HTML doesn't have a head tag" do
      pdfkit = IMGKit.new("<html><body>Hai!</body></html>")
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      pdfkit.to_pdf
      pdfkit.source.to_s.should include("<style>#{File.read(css)}</style><html>")
    end
    
    it "should throw an error if the source is not html and stylesheets have been added" do
      pdfkit = IMGKit.new('http://google.com')
      css = File.join(SPEC_ROOT,'fixtures','example.css')
      pdfkit.stylesheets << css
      lambda { pdfkit.to_pdf }.should raise_error(IMGKit::ImproperSourceError)
    end
  end
  
  context "#to_file" do
    before do
      @file_path = File.join(SPEC_ROOT,'fixtures','test.pdf')
      File.delete(@file_path) if File.exist?(@file_path)
    end
    
    after do
      File.delete(@file_path)
    end
    
    it "should create a file with the PDF as content" do
      pdfkit = IMGKit.new('html', :page_size => 'Letter')
      pdfkit.expects(:to_pdf).returns('PDF')
      file = pdfkit.to_file(@file_path)
      file.should be_instance_of(File)
      File.read(file.path).should == 'PDF'
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
      pdfkit = IMGKit.new('html', :header_center => "a title\"; touch #{@test_path} #")
      pdfkit.to_pdf
      File.exist?(@test_path).should be_false
    end
  end
  
end
