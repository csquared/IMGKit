class IMGKit
  class Configuration
    attr_writer :wkhtmltoimage
    attr_accessor :meta_tag_prefix, :default_options, :default_format

    def initialize
      @meta_tag_prefix = 'imgkit-'
      @default_options = {:height => 0}
      @default_format  = :jpg
    end

    def wkhtmltoimage
      @wkhtmltoimage ||= begin
        path = (using_bundler? ? `bundle exec which wkhtmltoimage` : `which wkhtmltoimage`).chomp
        path = '/usr/local/bin/wkhtmltoimage' if path.strip.empty?  # Fallback
        path
      end
    end

    private
    def using_bundler?
      defined?(Bundler::GemfileError)
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
