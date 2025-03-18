# kvm-automation-tooling

This is currently just a collection of notes, scripts, templates and data files for experimenting with automating kvm vms for local development.

## Dependencies

These are the versions I was using when I built this module.

* Ruby 3.2+
* Puppet 8+
* Bolt 4+
* Terraform 1.10+
* [libvirt](https://libvirt.org/) 10.0.0
* libvirt-dev (for the ruby bindings using ruby-libvirt from the Gemfile)

## Usage

Note: libvirt-dev must be installed before the ruby-libvirt gem will build.

```
bundle install
bolt module install
```

Usage will be principally through Bolt plans from the plans dir.

## Tests

The modules must have been installed first via 'bolt module install' so that
the spec modulepath in spec/spec_helper.rb can find them. The
spec/fixtures/modulepath/kvm_automation_tooling symlink is managed by
rspec-puppet itself.

```
bolt rspec spec
```
