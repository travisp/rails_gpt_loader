# frozen_string_literal: true

require_relative "lib/rails_gpt_loader/version"

Gem::Specification.new do |spec|
  spec.name = "rails_gpt_loader"
  spec.version = RailsGptLoader::VERSION
  spec.authors = ["Travis Pew"]
  # spec.email = ["TODO"]

  spec.summary = "Rails GPT Loader"
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = "https://github.com/travisp/rails_gpt_loader"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/travisp/rails_gpt_loader/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_development_dependency "standard", "~> 1.26", ">= 1.26"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
