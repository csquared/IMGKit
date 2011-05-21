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
  JPEG = "\xFF\xD8\xFF\xE0".force_encoding("UTF-8")
  PNG  = "\x89\x50\x4e\x47".force_encoding("UTF-8")

  def read(string)
    string[0,4]
  end
end

RSpec::Matchers.define :be_a_jpg do
  match do |actual|
    MagicNumber.read(actual) == MagicNumber::JPEG
  end
  failure_message_for_should do |actual|
    "expctected #{MagicNumber.read(actual).inspect} to equal #{MagicNumber::JPEG.inspect}"
  end
end

RSpec::Matchers.define :be_a_png do
  match do |actual|
    MagicNumber.read(actual) == MagicNumber::PNG
  end
  failure_message_for_should do |actual|
    "expctected #{MagicNumber.read(actual).inspect} to equal #{MagicNumber::PNG.inspect}"
  end
end
