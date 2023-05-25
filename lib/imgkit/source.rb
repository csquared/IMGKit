require 'uri'

class IMGKit

  class Source
    URL_REGEX = /\A#{URI.regexp(['http', 'https'])}\z/

    def initialize(url_file_or_html)
      @source = url_file_or_html
    end

    def url?
      @source.is_a?(String) && @source.match(URL_REGEX)
    end

    def file?
      @source.kind_of?(File) || @source.kind_of?(Tempfile)
    end

    def html?
      !(url? || file?)
    end

    def to_s
      file? ? @source.path : @source
    end

  end

end
