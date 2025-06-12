variable "libvirt_uri" {
  description = "The URI of the libvirt connection to use for creating VMs."
  type = string
  default = "qemu:///system"
}

variable "cluster_id" {
  description = "An identifier for the cluster, used as part of each vm hostname."
  type = string
  default = "dev"
}

variable "user_name" {
  description = "The name of the user account to create for ssh login on generated vm hosts."
  type = string
}

variable "ssh_public_key_path" {
  description = "The path to an SSH public key file to be added to the ssh authorized_keys file on generated vm hosts."
  type = string
}

variable "network_addresses" {
  description = "The network address range in CIDR notation to use for the generated libvirt network. The gateway address will be 'A.B.C.1'."
  type = string
}

variable "domain_name" {
  description = "The domain name to use for the generated libvirt network."
  type = string
}

variable "user_password" {
  description = "Optional password to set for the default user account on vm hosts (can be used for debugging ssh connectivity issues)."
  type = string
  default = ""
  nullable = false
}

variable "vm_specs" {
  description = "A map of vm specifications to use for generating VMs with the vm module. The keys are the unique role.hostname.platform string for each class of VMs, and the values are an object with configuration details for the vm module."
  type = map(object({
    # Identifier for the libvirt image pool to use for the VM images.
    pool_name = string
    # The name of the libvirt volume to use as the base image for the
    # VM images.
    base_volume_name = string
    # The name of the operating system being used on the vm.
    os = string
    # The number of CPUs to allocate to each vm.
    cpus      = optional(number)
    # The amount of memory in MB to allocate to each vm.
    mem_mb    = optional(number)
    # The size of each vm disk in GB.
    disk_gb   = optional(number)
    # The CPU mode to use for the VMs.
    # (Set to host-passthrough for nested virtualization.)
    cpu_mode  = optional(string)
  }))
}
