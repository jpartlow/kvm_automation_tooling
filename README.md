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
* genisoimage (for creating the cloud-init iso)

## Usage

Note: build-essential and libvirt-dev must be installed before the
ruby-libvirt gem and other gems that compile native libraries will build.
You may also need ruby-dev if you are using a system ruby package rather than
say an rbenv ruby.

If you are using an rbenv ruby, setup will look something like:

```bash
# Pre-requisites (Ubuntu/Debian)
sudo apt install build-essential libvirt-dev genisoimage
```

```bash
bundle install
bolt module install
```

If you are using a system ruby, setup will look something like:

```bash
sudo apt install build-essential ruby-dev libvirt-dev genisoimage
bundle install --path .bundle # or sudo bundle install if you prefer
bundle exec bolt module install
```

### Standup Cluster

Write a cluster_params.json file with parameters needed by the
[standup_cluster](plans/standup_cluster.pp) plan.

Example:

```json
{
  "cluster_name": "foo",
  "network_addresses": "192.168.100.0/24",
  "ssh_public_key_path": "/some/path/to/ssh/id_for_vms.pub",
  "os": "ubuntu",
  "os_version": "2404",
  "os_arch": "x86_64",
  "architecture": "singular",
  "vms": [
    {
      "role": "primary",
      "cpus": 8,
      "mem_mb": 8192,
      "disk_gb": 20,
    },
    {
      "role": "agent",
      "count": 2,
    }
  ]
}
```

(See the [Vm_spec datatype](types/vm_spec.pp) for the full set of
parameters that may be set for a given *vms* hash.)

```bash
bundle exec bolt plan run kvm_automation_tooling::standup_cluster --params @cluster_params.json
```

This will produce a cluster of a primary and one agent with a cluster_id string
of 'foo-singular-ubuntu-2404-amd64'. The terraform state files and a bolt
inventory file (distinguished by the cluster_id) will be found under the
terraform/instances/ directory.

### Teardown Cluster

To teardown the cluster, run the teardown_cluster plan with the cluster_id:

```bash
bundle exec bolt plan run kvm_automation_tooling::teardown_cluster cluster_id=foo-singular-ubuntu-2404-amd64
```

Note: You may need the vms active to run the teardown plan so that terraform
can read the network_interface.addresses.

## Tests

The modules must have been installed first via 'bolt module install' so that
the spec modulepath in spec/spec_helper.rb can find them. The
spec/fixtures/modulepath/kvm_automation_tooling symlink is managed by
rspec-puppet itself.

Note: You need a symlink of .modules/ruby_task_helper at
kvm_automation_tooling/../ruby_task_helper for task dependencies to load
correctly.

```
bundle exec rspec spec
```
