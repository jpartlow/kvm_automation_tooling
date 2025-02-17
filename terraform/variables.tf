variable "ssh_public_key_path" {
  description = "The path to an SSH public key file to be added to the ssh authorized_keys file on generate vm hosts."
  type = string
}

variable user_password {
  description = "Optional password to set for the default user account on vm hosts (can be used for debugging ssh connectivity issues)."
  type = string
  default = ""
}

variable bridge_ip {
  description = "The IP address of the bridge interface to use for the VM network."
  type = string
}

variable instance_id {
  description = "The instance ID to set for the VM."
  type = string
}

variable hostname {
  description = "The hostname to set for the VM."
  type = string
}
