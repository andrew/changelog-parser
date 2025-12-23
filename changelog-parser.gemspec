# frozen_string_literal: true

require_relative "lib/changelog/parser/version"

Gem::Specification.new do |spec|
  spec.name = "changelog-parser"
  spec.version = Changelog::Parser::VERSION
  spec.authors = ["Andrew Nesbitt"]
  spec.email = ["andrewnez@gmail.com"]

  spec.summary = "Parse changelog files into structured data"
  spec.description = "A Ruby gem for parsing changelog files. Supports Keep a Changelog format, " \
                     "markdown headers, and custom patterns."
  spec.homepage = "https://github.com/andrew/changelog-parser"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
