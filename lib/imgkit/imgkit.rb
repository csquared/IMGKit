class IMGKit
  KNOWN_FORMATS = [:jpg, :jpeg, :png, :tiff, :tif]

  class NoExecutableError < StandardError
    def initialize
      msg  = "No wkhtmltoimage executable found at #{IMGKit.configuration.wkhtmltoimage}\n"
      msg << ">> Install wkhtmltoimage by hand or try running `imgkit --install-wkhtmltoimage`"
      super(msg)
    end
  end
  
  class ImproperSourceError < StandardError
    def initialize(msg)
      super("Improper Source: #{msg}")
    end
  end

  class CommandFailedError < RuntimeError
    attr_reader :command, :stderr
    def initialize(command, stderr)
      @command = command
      @stderr  = stderr
      super("Command failed: #{command}: #{stderr}")
    end
  end

  class UnknownFormatError < StandardError
    def initialize(format)
      super("Unknown Format: #{format}")
    end
  end
  
  attr_accessor :source, :stylesheets
  attr_reader :options
  
  def initialize(url_file_or_html, options = {})
    @source = Source.new(url_file_or_html)
    
    @stylesheets = []

    @options = IMGKit.configuration.default_options.merge(options)
    @options.merge! find_options_in_meta(url_file_or_html) unless source.url?
    
    raise NoExecutableError.new unless File.exists?(IMGKit.configuration.wkhtmltoimage)
  end
  
  def command
    args = [executable]
    args += normalize_options(@options).to_a.flatten.compact
    
    if @source.html?
      args << '-' # Get HTML from stdin
    else
      args << @source.to_s
    end
    
    args << '-' # Read IMG from stdout
    args
  end

  def executable
    default = IMGKit.configuration.wkhtmltoimage
    return default if default !~ /^\// # its not a path, so nothing we can do
    if File.exist?(default)
      default
    else
      default.split('/').last
    end
  end
  
  def to_img(format = nil)
    append_stylesheets
    set_format(format)

    result = nil
    stderr_output = nil
    Open3.popen3(*command) do |stdin,stdout,stderr|
      stdin << (@source.to_s) if @source.html?
      stdin.close
      result = stdout.gets(nil)
      result.force_encoding("ASCII-8BIT") if result.respond_to? :force_encoding
      stderr_output = stderr.readlines.join
      stdout.close
      stderr.close
    end
    
    raise CommandFailedError.new(command.join(' '), stderr_output)  unless result
    return result
  end
  
  def to_file(path)
    format = File.extname(path).gsub(/^\./,'').to_sym
    set_format(format)
    File.open(path,'w:ASCII-8BIT') {|file| file << self.to_img}
  end

  def method_missing(name, *args, &block)
    if(m = name.to_s.match(/^to_(\w+)/))
      self.send(:to_img, m[1].to_sym)
    else
      super
    end
  end
  
  protected

    def find_options_in_meta(body)
      imgkit_meta_tags(body).inject({}) do |found, tag|
        name = tag.attributes["name"].sub(/^#{IMGKit.configuration.meta_tag_prefix}/, '').to_sym
        found.merge(name => tag.attributes["content"])
      end
    end

    def imgkit_meta_tags(body)
      require 'rexml/document'
      xml_body = REXML::Document.new(body)
      found = []
      xml_body.elements.each("html/head/meta") do |tag|
        found << tag if tag.attributes['name'].to_s =~ /^#{IMGKit.configuration.meta_tag_prefix}/
      end
      found
    rescue # rexml random crash on invalid xml
      []
    end
  
    def style_tag_for(stylesheet)
      "<style>#{stylesheet.respond_to?(:read) ? stylesheet.read : File.read(stylesheet)}</style>"
    end
    
    def append_stylesheets
      raise ImproperSourceError.new('Stylesheets may only be added to an HTML source') if stylesheets.any? && !@source.html?
      
      stylesheets.each do |stylesheet|
        if @source.to_s.match(/<\/head>/)
          @source.to_s.gsub!(/(<\/head>)/, style_tag_for(stylesheet)+'\1')
        else
          @source.to_s.insert(0, style_tag_for(stylesheet))
        end
      end
    end
  
    def normalize_options(options)
      normalized_options = {}

      options.each do |key, value|
        next if !value
        normalized_key = "--#{normalize_arg key}"
        normalized_options[normalized_key] = normalize_value(value)
      end
      normalized_options
    end
    
    def normalize_arg(arg)
      arg.to_s.downcase.gsub(/[^a-z0-9]/,'-')
    end
    
    def normalize_value(value)
      case value
      when TrueClass
        nil
      when Array
        value
      else
        value.to_s
      end
    end

    def set_format(format)
      format = IMGKit.configuration.default_format unless format
      @options.merge!(:format => format.to_s) unless @options[:format]
      raise UnknownFormatError.new(format) unless KNOWN_FORMATS.include?(@options[:format].to_sym)
    end
end
