# Patch Intention

To overcome the lack of support for --user-style-sheet option by wkhtmltoimage 0.10.0 rc2 as reported here http://code.google.com/p/wkhtmltopdf/issues/detail?id=387

      require 'imgkit'
      require 'restclient'
      require 'stringio'

      url = 'http://domain/path/to/stylesheet.css'
      css = StringIO.new( RestClient.get(url) )

      kit = IMGKit.new(<<EOD)
      <!DOCTYPE HTML>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <title>coolest converter</title>
      </head>
      <body>
        <div class="cool">image kit</div>
      </body>
      </html>
      EOD

      kit.stylesheets << css

# IMGKit

Create JPGs using plain old HTML+CSS. Uses [wkhtmltoimage](http://github.com/antialize/wkhtmltopdf) on the backend which renders HTML using Webkit.

Heavily based on [PDFKit](http://github.com/jdpace/pdfkit/).

## Install

### IMGKit

    gem install imgkit

### wkhtmltoimage
 * **Automatic**: `sudo imgkit --install-wkhtmltoimage`  
 install latest version into /usr/local/bin  
 (overwrite defaults with e.g. ARCHITECTURE=amd64 TO=/home/foo/bin)
 * By hand: http://code.google.com/p/wkhtmltopdf/downloads/list

## Usage
    
    # IMGKit.new takes the HTML and any options for wkhtmltoimage
    # run `wkhtmltoimage --extended-help` for a full list of options
    kit = IMGKit.new(html, :quality => 50)
    kit.stylesheets << '/path/to/css/file'
    
    # Get the image BLOB
    img = kit.to_img

    # New in 1.3!
    img = kit.to_img(:jpg)      #default
    img = kit.to_img(:jpeg)     
    img = kit.to_img(:png)
    img = kit.to_img(:tif)
    img = kit.to_img(:tiff)

    # Save the image to a file
    file = kit.to_file('/path/to/save/file.jpg')
    file = kit.to_file('/path/to/save/file.png')
    
    # IMGKit.new can optionally accept a URL or a File.
    # Stylesheets can not be added when source is provided as a URL of File.
    kit = IMGKit.new('http://google.com')
    kit = IMGKit.new(File.new('/path/to/html'))

    # Add any kind of option through meta tags
    IMGKit.new('<html><head><meta name="imgkit-quality" content="75"...

    # Format shortcuts - New in 1.3!
    IMGKit.new("hello").to_jpg       
    IMGKit.new("hello").to_jpeg      
    IMGKit.new("hello").to_png       
    IMGKit.new("hello").to_tif       
    IMGKit.new("hello").to_tiff      
    
## Configuration

If you're on Windows or you installed wkhtmltoimage by hand to a location other than /usr/local/bin you will need to tell IMGKit where the binary is. You can configure IMGKit like so:

    # config/initializers/imgkit.rb
    IMGKit.configure do |config|
      config.wkhtmltoimage = '/path/to/wkhtmltoimage'
      config.default_options = {
        :quality => 60
      }
      config.default_format = :png
    end

## Rails 

### Mime Types
register a .jpg mime type in: 

    #config/initializers/mime_type.rb
    Mime::Type.register       "image/jpeg", :jpg

register a .png mime type in: 

    #config/initializers/mime_type.rb
    Mime::Type.register       "image/png", :png

### Controller Actions
You can respond in a controller with:

    @kit = IMGKit.new(render_as_string)

    format.jpg do
      send_data(@kit.to_jpg, :type => "image/jpeg", :disposition => 'inline')
    end

    - or -

    format.png do
      send_data(@kit.to_png, :type => "image/png", :disposition => 'inline')
    end

    - or -

    respond_to do |format|
      send_data(@kit.to_img(format.to_sym), 
                :type => "image/png", :disposition => 'inline')
    end

This allows you to take advantage of rails page caching so you only generate the
image when you need to.

## Note on Patches/Pull Requests
 
* Fork the project.
* Setup your development environment with: gem install bundler; bundle install
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 <a href="mailto:christopher.continanza@gmail.com">Chris Continanza</a>
Based on work by Jared Pace  
See LICENSE for details.
