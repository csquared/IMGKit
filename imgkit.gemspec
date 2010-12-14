# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "imgkit/version"

Gem::Specification.new do |s|
  s.name        = "imgkit"
  s.version     = IMGKit::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors = ["csquared"]
  s.email = %q{christopher.continanza@gmail.com}
  s.homepage    = "http://rubygems.org/gems/imgkit"
  s.summary =  %q{HTML+CSS -> JPG}
  s.description = %q{Uses wkhtmltoimage to create Images using HTML}
  s.post_install_message = File.read('POST_INSTALL')

  s.rubyforge_project = "imgkit"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
