lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tokie/version'

Gem::Specification.new do |spec|
  spec.name          = "tokie"
  spec.version       = Tokie::VERSION
  spec.authors       = ["Kasper Timm Hansen"]
  spec.email         = ["kaspth@gmail.com"]
  spec.description   = %q{ Encrypt and decrypt, sign and verify JSON Web Tokens in Ruby. }
  spec.summary       = %q{  }
  spec.homepage      = "https://github.com/kaspth/tokie"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.test_files    = Dir["test/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 4.2"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
