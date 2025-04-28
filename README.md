# kvm_automation_tooling

A Bolt module for creating and destroying kvm vm clusters via libvirt.
Uses Terraform and the puppetlabs-terraform module to manage vm creation.
Uses cloud-init to configure user account, ssh keys and network.

Principally intended as a development/ci tool for OpenVox stack testing.

TODO:

* Add support for other OSes
  * EL, Alma
  * Fedora
  * SLES
  * ?
* Add support for other architectures?
* Finish OpenVox stack setup (openvox-server, openvox-db, postgresql)

## OS Support

* Debian 12, 11, 10
* Rocky 9, 8
* Ubuntu 24.04, 22.04, 20.04

## Dependencies

These are the versions I was using when I built this module.

* Ruby 3.2+
* Puppet 8+
* Bolt 4+
* Terraform 1.10+
* [libvirt](https://libvirt.org/) 10.0.0
* libvirt-dev (for the ruby bindings using ruby-libvirt from the Gemfile)
* genisoimage (for creating the cloud-init iso)

Note: Puppet and Bolt will also be installed as Gems by Bundler,
so installing those system packages is not strictly necessary.

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

The [kvm_automation_tooling::standup_cluster](plans/standup_cluster.pp) plan is
the main entry point for cluster automation.

Write a cluster_params.json file with parameters needed by the plan.

Example:

```json
{
  "cluster_id": "foo",
  "network_addresses": "192.168.100.0/24",
  "ssh_public_key_path": "/some/path/to/ssh/id_for_vms.pub",
  "os": "ubuntu",
  "os_version": "2404",
  "os_arch": "x86_64",
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

Then run the plan via Bolt:

```bash
bundle exec bolt plan run kvm_automation_tooling::standup_cluster --params @cluster_params.json
```

This will produce a cluster of a primary and one agent with a cluster_id string
of 'foo', and hostnames 'foo-primary-1' and 'foo-agent-1'
respectively. The terraform state files and a bolt inventory file
(distinguished by the cluster_id) will be found under the
terraform/instances/ directory.

#### RedHat Issues

RHEL 9 variants require x86_64-v2 support.

https://developers.redhat.com/blog/2021/01/05/building-red-hat-enterprise-linux-9-for-the-x86-64-v2-microarchitecture-level#recommendations_for_rhel_9

This could be set in the libvirt cpu model per
https://libvirt.org/formatdomain.html#cpu-model-and-topology (choosing
something like Nehalem as a lowest level of support), but the
terraform provider I'm using, dmacvicar/libvirt, does not support
setting a cpu model entry, just the overall cpu mode attribute.

https://github.com/dmacvicar/terraform-provider-libvirt/issues/1129

The workaround is to set the cpu_mode to host-model or
host-passthrough.

##### Rocky Issues

The Rocky 8 images are larger (2GB) than the Rocky 9 and Debian/Ubuntu
images (around 500MB), so take longer in gha when downloading.

Also, the Rocky images seem to define a 10GB partition, since, even
though
[KvmAutomationTooling::LibvirtWrapper.upload_image()](lib/kvm_automation_tooling/libvirt_wrapper.rb)
is specifying a 3GB default capacity, the capacity set in volume xml
ends up being 10GB. In practice this means that with these images, you
must specify a minimum disk size of 10GB for vms based on them. The
[terraform vm.disk_gb param](terraform/modules/vm/variables.tf) has a
10GB default, but if you override this to less than 10GB for a Rocky
vm, you will get an error similar to:

```
Finished: task terraform::apply with 1 failure in 0.8 sec
Finished: plan terraform::apply in 0.8 sec
Finished: plan kvm_automation_tooling::standup_cluster in 32.73 sec
Failed on localhost:

  Error: when 'size' is specified, it shouldn't
  be smaller than the backing store specified with
  'base_volume_id' or 'base_volume_name/base_volume_pool'

    with module.vmdomain["test-singular-rocky-9-x86_64-primary-1"].libvirt_volume.volume_qcow2,
    on modules/vm/main.tf line 10, in resource "libvirt_volume" "volume_qcow2":
    10: resource "libvirt_volume" "volume_qcow2" {
```

(I know you can grow partitionts with cloud-init; I'm not certain if
it's feasible to shrink them.)

### Teardown Cluster

To teardown the cluster, run the teardown_cluster plan with the cluster_id:

```bash
bundle exec bolt plan run kvm_automation_tooling::teardown_cluster cluster_id=foo
```

Note: You may need the vms active to run the teardown plan so that terraform
can read the network_interface.addresses.

### Inventory

The inventory file is generated by the standup_cluster plan and is
located in the terraform/instances/ as `inventory.<cluster_id>.yaml`.
The inventory file is a standard Bolt inventory file that relies on the
puppetlabs-terraform module's plugin to resolve inventory references from the
associated `terraform/instances/<cluster_id>.tfstate` file.

You can use this inventory file to run other Bolt plans, tasks or commands
against the cluster. Given the 'foo' cluster example above, you could run:

```bash
jpartlow@archimedes:~/work/src/kvm_automation_tooling$ be bolt command run --inventory terraform/instances/inventory.foo.yaml --targets foo-primary-1 'echo hi'
Started on foo-primary-1...
Finished on foo-primary-1:
  hi
Successful on 1 target: foo-primary-1
Ran on 1 target in 4.28 sec
```

## Images

### Removing Images

To clean up images, use virsh to remove the base volumes from the
default storage pool and delete the images from your download
directory (~/images by default).

```bash
virsh vol-delete --pool default --vol debian-13-generic-amd64.qcow2
rm ~/images/debian-13-generic-amd64.qcow2
```

## Tests

The modules must have been installed first via 'bolt module install' so that
the spec modulepath in spec/spec_helper.rb can find them. The
spec/fixtures/modulepath/kvm_automation_tooling symlink is managed by
rspec-puppet itself.

*Note: You need a symlink of .modules/ruby_task_helper at
kvm_automation_tooling/../ruby_task_helper for task dependencies to load
correctly.*

```
bundle exec rspec spec
```

## Github Actions

The module is tested via Github Actions. The actions are in the .github/workflows.

The module also provides a Github [action](./action.yaml) that can be used in
other repository workflows to standup a nested cluster using this module.

## License

Copyright (C) 2025 Joshua Partlow

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
