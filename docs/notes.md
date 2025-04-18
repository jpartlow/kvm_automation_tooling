# Ubuntu VMs

Source qcow2
Grabbed 2025-01-22
https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

Only has a root account, no password.

Manually, can use this to provide a root password before standing up image:

`virt-customize -a /var/lib/libvirt/images/noble-server-cloudimg-amd64.img --root-password password:<PASSWORD>`

Use virt-sysprep to add an ubuntu account and give it an ssh keypair?

Looking into packer templates in work/src/kvm-automation-tooling for something less manual.

or cloud-init, if the image has been built with it.

See: https://cloudinit.readthedocs.io/en/latest/index.html since these images
have cloud-init

* Note, parameters of actual configuration that you can set are based on the
  modules used. As an example, see
  https://cloudinit.readthedocs.io/en/latest/reference/modules.html#users-and-groups
  for details on parameters used in the user-data.yaml example used by the below recipe.

https://www.techchorus.net/posts/automating-virtual-machine-installation-using-libvirt-virsh-and-cloud-init/

* cd /var/lib/libvirt/images/ubuntu-2404-amd64
* `qemu-img create -b ../noble-server-cloudimg-amd64.base.qcow2 -f qcow2 -F qcow2 test1.ubuntu-2404-amd64.qcow2`
* Need to be able to customize
  work/src/kvm-automation-tooling/cloud-init/ubuntu-2404-amd64/network-config.yaml

Before

```
  virt-install \
  --name=test1.ubuntu-2404-amd64 \
  --ram=8192 \
  --vcpus=4 \
  --import \
  --disk path=test1.ubuntu-2404-amd64.qcow2,format=qcow2 \
  --os-variant=ubuntu24.04 \
  --network bridge=virbr0,model=virtio \
  --graphics none \
  --noautoconsole \
  --cloud-init user-data=/home/jpartlow/work/src/kvm-automation-tooling/cloud-init/ubuntu-2404-amd64/user-data.yaml,meta-data=/home/jpartlow/work/src/kvm-automation-tooling/cloud-init/ubuntu-2404-amd64/meta-data.yaml,network-config=/home/jpartlow/work/src/kvm-automation-tooling/cloud-init/ubuntu-2404-amd64/network-config.yaml
```

But I also need to understand the basics of kvm networking with libvirt.

The above started up a vm that I could ping, and had a running ssh, but did not
allow login as ubuntu with my `id_vm` key.  Should probably add a password for
ubuntu so I can log in and poke around (see the recipe url for details on
that). *Issue was just that I had lost the magic #cloud-config header for the
cloud-init user-data.yaml file, so the user credentials weren't getting
updated.*

# Troubleshooting terraform

Using `terraform apply`, I'm running into a few snags.

First using the "dmacvicar/libvirt" provider, there's the basic problem that
the libvirt_pool resource, which is a directory pool tied to a specific
/var/lib/libvirt/images directory fails if the directory already exists.
(Actually, I think it's not the existence of the physical directory, but rather
a leftover libvirt pool configuration that's the problem. `virsh pool-list
--all` will show even inactive pools, and `virsh pool-undefine <pool-name>`
will remove it). Working around this requires a manual `terraform import` first.

But if I ensure that the directory doesn't exist, then the provider creates it
and the domain file, but with root:root 711 permissions that then can't be
started.

Looking into this using terraform logging variables:

```bash
# export TF_LOG=DEBUG # everything
export TF_LOG_PROVIDER=DEBUG # just provider
export TF_LOG_CORE=INFO # just terraform core
export TF_LOG_PATH=./tf.wtf.log
```

That didn't tell me anything. Trying TF_LOG=DEBUG now.
Which also didn't tell me anything. And the /var/log/libvirt/qemu/ log files
just provide output from the attempt to start the domain, which fails because
of the above permission issue...

The general syslog output for libvirt is also not helpful.

Manually, I was using qemu-img and virt-install.

Problem is discussed here:
https://github.com/dmacvicar/terraform-provider-libvirt/issues/546

The workaround is noted here:
https://github.com/dmacvicar/terraform-provider-libvirt/commit/22f096d9

Despite selinux not being in use, it's necessary to set security_driver to
"none" in /etc/libvirt/qemu.conf and restart the libvirtd service to avoid qemu
enforcing it.

So the terraform apply works now.

Now I need to figure out the networking. It needs a bridge. The manual
configuration works, not sure yet how to specify the bridge in the terraform
configuration.

Alright,
https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs/resources/domain#bridge-1
isn't super clear, but it's simply a matter of specifying
libvirt_domain.network_interface.bridge in the domain resource, in my case to
"virbr0" which is what virt-manager generated by default.

Then the cloud-init network-config.yaml file needed to be updated to use dhcp
and bind more generally to any virtio named interface (via "match"
https://cloudinit.readthedocs.io/en/latest/reference/network-config-format-v2.html#match-mapping).

A `terraform apply` now starts up a vm that I can ssh into as ubuntu with my id_vms key.

## networking

The bridge is created by libvirt, and the interface to it is visible in `ip a` as virbr0.

Name resolution from the host to the guests can be setup simply using libnss-libvirt.

```bash
sudo apt install libnss-libvirt
```

Need to manually update /etc/nsswitch.conf to include libvirt and libvirt_guest in the hosts line.
On ubuntu 24.04, I ended up with:

```bash
hosts: files mdns4_minimal libvirt libvirt_guest [NOTFOUND=return] dns mymachines
```

Name resolution between guests can be added to the libvirt network definition. For the default network, for example, can add (via `virsh net-edit`):

```xml
  <domain name='vm' localOnly='yes'/>
```

Need to restart the network for the changes to take effect. (via `virsh net-destroy default` and `virsh net-start default`).

### machine-id

Beware /etc/machine-id. The base image shouldn't have one, so that it can
be generated automatically during bootstrap. But if you have accidentally
started up a vm using the base image alone, then it will already have a
machine-id, and new vms using that image for a base will end up with the
same base-id which will destroy networking. The dhcpd dnsmasq daemon will
assign the same ip to multiple vms based on the machine-id. Which doesn't
work well.
