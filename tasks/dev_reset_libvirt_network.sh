set -e

# PT_* variables are set by Bolt.
# shellcheck disable=SC2154
network_name="${PT_name}"
# shellcheck disable=SC2154
original_network_prefix="${PT_original_network_prefix}"
# shellcheck disable=SC2154
new_network_prefix="${PT_new_network_prefix}"

network_xml_file="/tmp/${network_name}_network.xml"

export LIBVIRT_DEFAULT_URI="qemu:///system"

virsh net-dumpxml "${network_name}" > "${network_xml_file}"
cat "${network_xml_file}"

sed -i -e "s/${original_network_prefix}/${new_network_prefix}/g" "${network_xml_file}"
cat "${network_xml_file}"

#virsh net-destroy default
#virsh net-undefine default

virsh net-define "${network_xml_file}"
virsh net-list --all
ip addr
