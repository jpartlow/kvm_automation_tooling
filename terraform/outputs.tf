output "vm_info" {
  description = "A hash of vm ip addresses, role and platform metadata indexed by hostname."
  value = merge(
    [
      for o in module.vmdomain: o.vmdomain_details
    ]...
  )
}
