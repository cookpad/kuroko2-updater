lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "kuroko2/updater/version"

Gem::Specification.new do |spec|
  spec.name          = "kuroko2-updater"
  spec.version       = Kuroko2::Updater::VERSION
  spec.authors       = ["Ed Robinson"]
  spec.email         = ["edward-robinson@cookpad.com"]
  spec.summary       = "A tool to manage kuroko2 job-definitions based on a schedule.rb file"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "faraday", ">= 0.15"
  spec.add_dependency "faraday_middleware", ">= 0.13"
  spec.add_dependency "whenever", "~> 0.11"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.71"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rails"
end
