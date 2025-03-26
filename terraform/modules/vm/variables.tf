variable "cluster_id" {
  description = "An identifier for the cluster, used as part of each generated libvirt object id."
  type = string
}

variable "hostname" {
  description = "The hostname to set for the VM."
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

variable "cpus" {
  description = "The number of CPUs to allocate to the VM."
  type = number
}

variable "memory" {
  description = "The amount of memory in MB to allocate to the VM."
  type = number
}

variable "disk_size" {
  description = "The size of the VM disk in GB."
  type = number
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
