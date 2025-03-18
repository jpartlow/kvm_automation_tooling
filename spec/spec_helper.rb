# frozen_string_literal: true

require 'rspec-puppet'

module KatRspec
  def self.fixture_path
    File.expand_path(File.join(__dir__, 'fixtures'))
  end

  def self.modulepath
    [
      # spec/fixtures/modules is where rspec-puppet autogenerates
      # a symlink for the module being tested
      File.join(fixture_path, 'modules'),
      # .modules is where bolt puts its modules (all of our dependencies)
      File.join(__dir__, '..', '.modules'),
    ]
  end
end

RSpec.configure do |c|
  # Include the Bolt .modules directory as part of the modulepath for
  # dependencies. Joined because rspec-puppet can only deal with a
  # multi-element modulepath as a string.
  c.module_path     = KatRspec.modulepath.join(File::PATH_SEPARATOR)
  c.manifest        = File.join(KatRspec.fixture_path, 'manifests', 'site.pp')
  c.environmentpath = File.join(Dir.pwd, 'spec', 'environments')
end

require 'bolt_spec/plans'

RSpec.shared_context 'plan_init' do
  include BoltSpec::Plans

  # This should still execute before the before(:all)
  # See: https://rspec.info/features/3-12/rspec-core/hooks/around-hooks/
  around(:example) do |example|
    old_modpath = RSpec.configuration.module_path
    # This bit of insanity is due to the fact that rspec-puppet can only
    # deal with a module:path, while BoltSpec can only deal with a
    # [module, path]...
    RSpec.configuration.module_path = KatRspec.modulepath
    example.run
  ensure
    RSpec.configuration.module_path = old_modpath
  end

  before(:all) do
    BoltSpec::Plans.init
  end
end
