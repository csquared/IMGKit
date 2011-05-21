class IMGKit
  class Configuration
    attr_accessor :meta_tag_prefix, :wkhtmltoimage, :default_options, :default_format

    def initialize
      @meta_tag_prefix = 'imgkit-'
      @wkhtmltoimage   = '/usr/local/bin/wkhtmltoimage'
      @default_options = {}
      @default_format  = :jpg
    end
  end

  class << self
    attr_accessor :configuration
  end

  # Configure IMGKit someplace sensible,
  # like config/initializers/imgkit.rb
  #
  # @example
  #   IMGKit.configure do |config|
  #     config.wkhtmltoimage = '/usr/bin/wkhtmltoimage'
  #   end
  
  def self.configuration
    @configuration ||= Configuration.new
  end
  
  
  def self.configure
    self.configuration 
    yield(configuration)
  end
end
