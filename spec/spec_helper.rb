# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # RSpec v4 forward-compat
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # RSpec v4 forward-compat
    mocks.verify_partial_doubles = true
  end

  # RSpec v4 forward-compat
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options.
  config.example_status_persistence_file_path = "spec/.examples"

  config.disable_monkey_patching!
  #config.warnings = true

  # Run specs in random order to surface order dependencies.
  config.order = :random
  Kernel.srand config.seed

=begin
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end
=end
end

require 'bundler'
Bundler.require :default
require_relative '../lib/logs.rb'
require_relative '../lib/rogare.rb'

module Rogare
  class << self
    def bot
      Cinch::Bot.new
    end
  end
end

