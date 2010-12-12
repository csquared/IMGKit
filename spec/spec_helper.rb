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
