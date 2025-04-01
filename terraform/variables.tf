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

variable "pool_name" {
  description = "Identifier for the libvirt image pool to use for the VM images."
  type = string
}

variable "base_volume_name" {
  description = "The name of the libvirt volume to use as the base image for the VM images."
  type = string
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

variable "cpu_mode" {
  description = "The CPU mode to use for the VMs."
  type = string
}

########################################################################
# Primary node variables

variable "primary_count" {
  description = "The number of primary nodes to create in the cluster."
  type = number
  default = 1
  validation {
    condition     = var.primary_count >= 0 && var.primary_count <= 1
    error_message = "The primary_count may be 0 or 1."
  }
}

variable "primary_cpus" {
  description = "The number of CPUs to allocate to the primary node."
  type = number
  default = 4
}

variable "primary_memory" {
  description = "The amount of memory in MB to allocate to the primary node."
  type = number
  default = 8192
}

variable "primary_disk_size" {
  description = "The size of the primary node disk in GB."
  type = number
  default = 20
}

########################################################################
# Agent node variables

variable "agent_count" {
  description = "The number of agent nodes to create in the cluster."
  type = number
}

variable "agent_cpus" {
  description = "The number of CPUs to allocate to each agent node."
  type = number
  default = 2
}

variable "agent_memory" {
  description = "The amount of memory in MB to allocate to each agent node."
  type = number
  default = 2048
}

variable "agent_disk_size" {
  description = "The size of each agent node disk in GB."
  type = number
  default = 10
}
