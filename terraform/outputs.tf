output "vm_ip_addresses" {
  description = "A hash of vm ip addresses indexed by hostname."
  value = merge([for o in module.vmdomain: o.ip_address]...)
}
