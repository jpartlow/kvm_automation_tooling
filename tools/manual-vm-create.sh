#! /bin/bash

set -e

vm_number=$1
vm_arch=$2
gen_cloud_init_flag=$3

if [ "$gen_cloud_init_flag" = "--gen-cloud-init-iso" ]; then
  gen_cloud_init_iso=true
fi

images_dir="/var/lib/libvirt/images"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cloud_init_dir="${script_dir}/manual-vm-create.cloud-init.d/ubuntu"

if [[ -z "$vm_number" || -z "$vm_arch"  ||
  ( -n "$gen_cloud_init_flag" &&
   "$gen_cloud_init_flag" != "--gen-cloud-init-iso" ) ]]; then
  echo "Usage: $0 <vm_number> <vm_arch> [--gen-cloud-init-iso]"
  echo
  cat <<EOS
This is a very basic tool for creating either an ubuntu 24.04 amd64
or arm64 VM using virt-install and qemu-img for the purpose of 
initial image troubleshooting.

It assumes a base ubuntu-24.04 cloud image has already been
downloaded and stored at:
  ${images_dir}/noble-server-cloudimg-<vm_arch>.img,
and it will create an image for the vm at:
  ${images_dir}/ubuntu-2404-<vm_arch>/.

The call to qemu-img uses sudo.

It makes hostname adjustments in the cloud-init meta-data yaml at:
  ${cloud_init_dir}/meta-data.

It also assumes you have a libvirt network named 'virbr3' already
created with the gateway indicated by:
  ${cloud_init_dir}/network-config.

And it prompts for a root password to be set in the image using
virt-customize.

This is critical for troubleshooting if the network fails to come
up.

  --gen-cloud-init-iso

    If provided, will also generate a cloud-init ISO image in the
    same directory as the VM image to be used instead of the
    --cloud-init option to virt-install. This is purely to help
    debug problems with the virt-install --cloud-init process related,
    mysteriously, to arm64 images.
EOS
  exit 1
fi
if [ "$vm_arch" != "amd64" ] && [ "$vm_arch" != "arm64" ]; then
  echo "Error: vm_arch must be either 'amd64' or 'arm64'"
  exit 1
fi

vm_name="u2404-${vm_arch}-manual-${vm_number}"
image_dir="${images_dir}/ubuntu-2404-${vm_arch}"
image_name="manual-test-${vm_number}.ubuntu-2404-${vm_arch}.qcow2"
image_path="${image_dir}/${image_name}"
cloud_init_iso_path="${image_dir}/manual-test-${vm_number}.ubuntu-2404-${vm_arch}-cloud-init.iso"

if [ -f "${image_path}" ]; then
  echo "Error: ${image_path} already exists."
  exit 1
fi

if [[ "$gen_cloud_init_iso" = true &&
   -f "${cloud_init_iso_path}" ]]; then
  echo "Error: ${cloud_init_iso_path} already exists."
  exit 1
fi

read -rsp "Enter root password for VM (enter skips): " PASSWORD
echo

echo "* Creating image at ${image_path}:"
set -x
sudo qemu-img create -b "${images_dir}/noble-server-cloudimg-${vm_arch}.img" -f qcow2 -F qcow2 "${image_path}"
set +x

if [ -n "$PASSWORD" ]; then
  echo "* Setting root password in ${image_path}."
  sudo virt-customize -a "${image_path}" --root-password "password:${PASSWORD}"
else
  echo "W: Skipping setting root password."
fi

echo "* Overwriting ${cloud_init_dir}/meta-data for hostname ${vm_name}."
sed -e "s/^\(instance-id:\).*/\1 abcdefgh-${vm_name}/" \
    -e "s/^\(local-hostname:\).*/\1 ${vm_name}/" \
    -i "${cloud_init_dir}/meta-data"

if [ "$gen_cloud_init_iso" = true ]; then
  echo "* Generating cloud-init ISO at ${cloud_init_iso_path}."
  sudo genisoimage -output "${cloud_init_iso_path}" -volid cidata -joliet -rock \
    "${cloud_init_dir}/user-data" \
    "${cloud_init_dir}/meta-data" \
    "${cloud_init_dir}/network-config"
    cloud_init_args=(--disk "path=${cloud_init_iso_path},device=cdrom")
else
  echo "* Using virt-install --cloud-init with files in ${cloud_init_dir}."
  cloud_init_args=(--cloud-init "user-data=${cloud_init_dir}/user-data,meta-data=${cloud_init_dir}/meta-data,network-config=${cloud_init_dir}/network-config")
fi

echo "* Creating vm ${vm_name}."
if [ "$vm_arch" = "amd64" ]; then
  arch_flag="x86_64"
else
  arch_flag="aarch64"
fi

# Note: added the --controller line per
# https://github.com/virt-manager/virt-manager/issues/445
# but hasn't had an effect.
# Could also need to bump libvirt from 10.0.0 11.6
# https://libvirt.org/news.html ?

flags=(
  "--name=${vm_name}"
  --ram=8192
  --vcpus=4
  --import
  --disk "path=${image_path},format=qcow2"
  --os-variant=ubuntu24.04
  --network "bridge=virbr3,model=virtio"
  --controller "type=scsi,model=virtio-scsi"
  --graphics none
  --noautoconsole
  "--arch=${arch_flag}"
  "${cloud_init_args[@]}"
  --debug
)

set -x
virt-install "${flags[@]}"
