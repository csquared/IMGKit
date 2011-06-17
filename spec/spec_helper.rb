SPEC_ROOT = File.dirname(__FILE__)
$LOAD_PATH.unshift(SPEC_ROOT)
$LOAD_PATH.unshift(File.join(SPEC_ROOT, '..', 'lib'))
require 'imgkit'
require 'rspec'
require 'rspec/autorun'
require 'mocha'
require 'rack'
require 'tempfile'

RSpec.configure do |config|
  config.before do
    IMGKit.any_instance.stubs(:wkhtmltoimage).returns(
      File.join(SPEC_ROOT,'..','bin','wkhtmltoimage-proxy')
    )
  end
end

module MagicNumber
  extend self
  JPG  = "\xFF\xD8\xFF\xE0"
  JPEG = JPG
  PNG  = "\x89\x50\x4e\x47"
  TIFF = "\x49\x49\x2a\x00"
  TIF  = TIFF
  GIF  = "\x47\x49\x46\x38"


  if "".respond_to?(:force_encoding) 
    constants.each { |c| const_get(c).force_encoding("ASCII-8BIT")  }
  end

  def read(string)
    string[0,4]
  end
end

RSpec::Matchers.define :be_a do |expected|
  match do |actual|
    @expected = MagicNumber.const_get(expected.to_s.upcase)
    MagicNumber.read(actual) == @expected
  end

  failure_message_for_should do |actual|
    actual = MagicNumber.read(actual)
    "expctected #{actual.inspect},#{actual.encoding} to equal #{@expected.inspect},#{@expected.encoding}"
  end
end
