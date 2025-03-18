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
