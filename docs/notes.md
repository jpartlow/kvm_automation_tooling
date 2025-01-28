# Ubuntu VMs

Source qcow2
Grabbed 2025-01-22
https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd65.img

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

But I also need to understand the basics of kvm networking with libvirt.

The above started up a vm that I could ping, and had a running ssh, but did not
allow login as ubuntu with my `id_vm` key.  Should probably add a password for
ubuntu so I can log in and poke around (see the recipe url for details on
that). *Issue was just that I had lost the magic #cloud-config header for the
cloud-init user-data.yaml file, so the user credentials weren't getting
updated.*
