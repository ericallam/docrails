# frozen_string_literal: true

version = File.read(File.expand_path("../RAILS_VERSION", __dir__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = "activerecord"
  s.version     = version
  s.summary     = "Object-relational mapper framework (part of Rails)."
  s.description = "Databases on Rails. Build a persistent domain model by mapping database tables to Ruby classes. Strong conventions for associations, validations, aggregations, migrations, and testing come baked-in."

  s.required_ruby_version = ">= 2.2.2"

  s.license = "MIT"

  s.author   = "David Heinemeier Hansson"
  s.email    = "david@loudthinking.com"
  s.homepage = "http://rubyonrails.org"

  s.files        = Dir["CHANGELOG.md", "MIT-LICENSE", "README.rdoc", "examples/**/*", "lib/**/*"]
  s.require_path = "lib"

  s.extra_rdoc_files = %w(README.rdoc)
  s.rdoc_options.concat ["--main",  "README.rdoc"]

  s.metadata = {
    "source_code_uri" => "https://github.com/rails/rails/tree/v#{version}/activerecord",
    "changelog_uri"   => "https://github.com/rails/rails/blob/v#{version}/activerecord/CHANGELOG.md"
  }

  s.add_dependency "activesupport", version
  s.add_dependency "activemodel",   version

  s.add_dependency "arel", ">= 9.0"
end
