variable "vm_id" {
  description = "A tripartite id for the vm made up of role.hostname.platform strings."
  type = string
}

variable "pool_name" {
  description = "The libvirt image pool to generate the VM's image in."
  type = string
}

variable "base_volume_name" {
  description = "The name of the base volume to use as the backing image for the VM."
  type = string
}

variable "os" {
  description = "The name of the operating system being used on the VM."
  type = string
}

variable "cpu_mode" {
  description = "The CPU mode to use for the VM."
  type = string
}

variable "cpus" {
  description = "The number of CPUs to allocate to the VM."
  type = number
  default = 1
  nullable = false
}

variable "mem_mb" {
  description = "The amount of memory in MB to allocate to the VM."
  type = number
  default = 1024
  nullable = false
}

variable "disk_gb" {
  description = "The size of the VM disk in GB."
  type = number
  default = 10
  nullable = false
}

variable "user_name" {
  description = "The name of the user account to create on the VM for ssh login."
  type = string
}

variable "ssh_public_key" {
  description = "The SSH public key to be added to the ssh authorized_keys file on generated vm hosts."
  type = string
}

variable "user_password" {
  description = "Optional password to set for the default user account on vm hosts (can be used for debugging ssh connectivity issues)."
  type = string
  default = ""
  nullable = false
}

variable "gateway_ip" {
  description = "The ip address for the network gateway to be used for routing and dns."
  type = string
}

variable "network_id" {
  description = "The libvirt network to attach the VM to."
  type = string
}

variable "domain_name" {
  description = "The domain name to use for the VM."
  type = string
}
