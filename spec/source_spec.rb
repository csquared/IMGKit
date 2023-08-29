require 'spec_helper'

describe IMGKit::Source do

  describe "#url?" do
    it "should return true if passed a url like string" do
      source = IMGKit::Source.new('http://google.com')
      expect(source).to be_url
    end

    it "should return false if passed a file" do
      source = IMGKit::Source.new(File.new(__FILE__))
      expect(source).to_not be_url
    end

    it "should return false if passed HTML" do
      source = IMGKit::Source.new('<blink>Oh Hai!</blink>')
      expect(source).to_not be_url
    end

    it "should return false if passed HTML with a line starting with 'http'" do
      source = IMGKit::Source.new("<blink>Oh Hai!</blink>\nhttp://google.com")
      expect(source).to_not be_url
    end
  end

  describe "#file?" do
    it "should return true if passed a file" do
      source = IMGKit::Source.new(File.new(__FILE__))
      expect(source).to be_file
    end

    it "should return true if passed a temporary file" do
      source = IMGKit::Source.new(Tempfile.new 'temp_file')
      expect(source).to be_file
    end

    it "should return false if passed a url like string" do
      source = IMGKit::Source.new('http://google.com')
      expect(source).to_not be_file
    end

    it "should return false if passed HTML" do
      source = IMGKit::Source.new('<blink>Oh Hai!</blink>')
      expect(source).to_not be_file
    end
  end

  describe "#html?" do
    it "should return true if passed HTML" do
      source = IMGKit::Source.new('<blink>Oh Hai!</blink>')
      expect(source).to be_html
    end

    it "should return false if passed a file" do
      source = IMGKit::Source.new(File.new(__FILE__))
      expect(source).to_not be_html
    end

    it "should return false if passed a url like string" do
      source = IMGKit::Source.new('http://google.com')
      expect(source).to_not be_html
    end
  end

  describe "#to_s" do
    it "should return the HTML if passed HTML" do
      source = IMGKit::Source.new('<blink>Oh Hai!</blink>')
      expect(source.to_s).to eq '<blink>Oh Hai!</blink>'
    end

    it "should return a path if passed a file" do
      source = IMGKit::Source.new(File.new(__FILE__))
      expect(source.to_s).to eq __FILE__
    end

    it "should return the url if passed a url like string" do
      source = IMGKit::Source.new('http://google.com')
      expect(source.to_s).to eq 'http://google.com'
    end
  end

end
