output "primary_ip_address" {
  description = "The IP address of the primary vm."
  value = module.primary.ip_address
}

output "agent_ip_addresses" {
  description = "An array of the IP addresses of the agent vms."
  value = module.agent[*].ip_address
}
