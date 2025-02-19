variable "cluster" {
  description = "An identifier for the cluster, used along with platform as part of each vm hostname."
  type = string
  default = "dev"
}

variable "platform" {
  description = "The operating system platform to use for the VMs. This is a constrained key of os name, version and architecture."
  type = string
  validation {
    condition = contains(local.allowed_platforms, var.platform)
    error_message = "The platform must be one of ${join(", ", local.allowed_platforms)}."
  }
}

variable "ssh_public_key_path" {
  description = "The path to an SSH public key file to be added to the ssh authorized_keys file on generate vm hosts."
  type = string
}

variable "user_password" {
  description = "Optional password to set for the default user account on vm hosts (can be used for debugging ssh connectivity issues)."
  type = string
  default = ""
}

variable "bridge_ip" {
  description = "The IP address of the bridge interface to use for the VM network."
  type = string
}

################################################################################
# Primary node variables

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

################################################################################
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
