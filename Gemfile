source 'https://rubygems.org'

gem 'puppet', '~> 8.0'
gem 'nokogiri', '~> 1.18'
gem 'ruby-libvirt', '~> 0.8.0'
# These two provide ed25519 key support for net-ssh
gem 'ed25519', ['>= 1.2', '< 2.0']
gem 'bcrypt_pbkdf', ['>= 1.0', '< 2.0']

group :development do
  gem 'bolt', '~> 4.0' # provides bolt_spec for tests
  gem 'pry-byebug'
  gem 'puppet-lint'
  gem 'voxpupuli-puppet-lint-plugins', '~> 5.0'
  gem 'puppet-strings'
  gem 'rspec', '~> 3.0'
  gem 'rspec-puppet', '~> 5.0'
  gem 'rspec-puppet-facts', '~> 5.0'
end
