require_relative 'lib/rb_pager/version'

Gem::Specification.new do |spec|
  spec.name          = "rb_pager"
  spec.version       = RbPager::VERSION
  spec.authors       = ["BambangSinaga"]
  spec.email         = ["mejbambang@gmail.com"]

  spec.summary       = "Cursor based pagination for active_record currently"
  spec.description   = %q{ActiveRecord plugin for cursor based pagination for Ruby on Rails. \n
    Cursor-based pagination (aka keyset pagination) is a common pagination strategy that avoids many of the pitfalls of “offset–limit” pagination.}
  spec.homepage      = "https://github.com/BambangSinaga/rb_pager"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org/"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/BambangSinaga/rb_pager"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "rspec"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
