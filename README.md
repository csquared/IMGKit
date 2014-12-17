# IMGKit

<img src="https://travis-ci.org/csquared/IMGKit.svg?branch=master" />

Create JPGs using plain old HTML+CSS. Uses [wkhtmltoimage](http://github.com/antialize/wkhtmltopdf) on the backend which renders HTML using Webkit.

Heavily based on [PDFKit](http://github.com/jdpace/pdfkit/).

## Install

### IMGKit

    gem install imgkit

### wkhtmltoimage
 1. Use installer: `sudo imgkit --install-wkhtmltoimage`
 install latest version into /usr/local/bin
 (overwrite defaults with e.g. ARCHITECTURE=amd64 TO=/home/foo/bin)
 2. Install by hand: [http://wkhtmltopdf.org/downloads.html](http://wkhtmltopdf.org/downloads.html)
 3. Try using the `wkhtmltoimage-binary` gem (mac + linux)
```
gem install wkhtmltoimage-binary
```

## Usage

    # IMGKit.new takes the HTML and any options for wkhtmltoimage
    # run `wkhtmltoimage --extended-help` for a full list of options
    kit = IMGKit.new(html, :quality => 50)
    kit.stylesheets << '/path/to/css/file'
    kit.javascripts << '/path/to/js/file'

    # Get the image BLOB
    img = kit.to_img

    # New in 1.3!
    img = kit.to_img(:jpg)      #default
    img = kit.to_img(:jpeg)
    img = kit.to_img(:png)

    # Save the image to a file
    file = kit.to_file('/path/to/save/file.jpg')
    file = kit.to_file('/path/to/save/file.png')

    # IMGKit.new can optionally accept a URL or a File.
    # Stylesheets nor Javascripts can not be added when source is provided as a URL of File.
    kit = IMGKit.new('http://google.com')
    kit = IMGKit.new(File.new('/path/to/html'))

    # Add any kind of option through meta tags
    IMGKit.new('<html><head><meta name="imgkit-quality" content="75"...

    # Format shortcuts - New in 1.3!
    IMGKit.new("hello").to_jpg
    IMGKit.new("hello").to_jpeg
    IMGKit.new("hello").to_png

    Note: Ruby's buffered I/O means that if you want to write the string data to a file or tempfile make sure to call `#flush` to ensure the contents don't get stuck in the buffer.

## Configuration

### `wkhtmltoimage` binary location

If you're on Windows or you installed `wkhtmltoimage` by hand to a location other than `/usr/local/bin` you will need to tell IMGKit where the binary is. You can configure IMGKit like so:

    # config/initializers/imgkit.rb
    IMGKit.configure do |config|
      config.wkhtmltoimage = '/path/to/wkhtmltoimage'
    end

### Default image format

May be set to one of [`IMGKit::KNOWN_FORMATS = [:jpg, :jpeg, :png]`](https://github.com/csquared/IMGKit/blob/master/lib/imgkit/imgkit.rb#L2)

      config.default_format = :png

### Prefix for `<meta>` tag options (see **Usage**) :

May be changed from its default (`imgkit-`):

      config.meta_tag_prefix = 'imgkit-option'

### Additional default options

Any flag accepted by `wkhtmltoimage` may be set thus:

      config.default_options = {
        :quality => 60
      }

For a flag which takes no parameters, use `true` for the value:

        'no-images' => true

For flags with multiple parameters, use an array:

        :cookie => ['my_session', '123BADBEEF456']

### Overriding options

When initializing an `IMGKit` options may be may be set for the life time of the `IMGKit` object:

    IMGKit.new('http://example.com/form', :post => ['my_field', 'my_unique_value'])

## Heroku

get a version of `wkhtmltoimage` as an amd64 binary and commit it
to your git repo.  I like to put mine in "./bin/wkhtmltoimage-amd64"

<a href="http://code.google.com/p/wkhtmltopdf/downloads/detail?name=wkhtmltoimage-0.10.0_rc2-static-amd64.tar.bz2&can=1&q=amd64">
version 0.10.0 has worked best for me
</a>

assuming its in that location you can just do:

    IMGKit.configure do |config|
      config.wkhtmltoimage = Rails.root.join('bin', 'wkhtmltoimage-amd64').to_s if ENV['RACK_ENV'] == 'production'
    end

If you're not using Rails just replace Rails.root with the root dir of your app.


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

    @kit = IMGKit.new(render_to_string)

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

## --user-style-sheet workaround
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

## Paperclip Example

Model:

```ruby
class Model < ActiveRecord::Base
  # attr_accessible :title, :body
   has_attached_file :snapshot, :storage => :s3,
        :s3_credentials => "#{Rails.root}/config/s3.yml"
end
```

Controller:

```ruby
def upload_image
   model = Model.find(params[:id])
   html  = render_to_string
   kit   = IMGKit.new(html)
   img   = kit.to_img(:png)
   file  = Tempfile.new(["template_#{model.id}", 'png'], 'tmp',
                         :encoding => 'ascii-8bit')
   file.write(img)
   file.flush
   model.snapshot = file
   model.save
   file.unlink
end
```



## CarrierWave Workaround

Contributed by @ticktricktrack

```ruby
  class MyClass < ActiveRecord::Base
    mount_uploader :snapshot, SnapshotUploader

    after_create :take_snapshot

    # private

    def take_snapshot
      file = Tempfile.new(["template_#{self.id.to_s}", 'jpg'], 'tmp', :encoding => 'ascii-8bit')
      file.write(IMGKit.new(self.html_body, quality: 50, width: 600).to_jpg)
      file.flush
      self.snapshot = file
      self.save
      file.unlink
    end
  end
```


## Note on Patches/Pull Requests

* Fork the project.
* Setup your development environment with: gem install bundler; bundle install
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Testing

Travis.yml is configured for multiple rubies, so I would just test a 2.1.x version and let travis handle the rest.

## Copyright

Copyright (c) 2010 <a href="mailto:christopher.continanza@gmail.com">Chris Continanza</a>
Based on work by Jared Pace
See LICENSE for details.
