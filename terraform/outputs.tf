output "vmdomain_details" {
  description = "A hash of vm ip addresses, role and platform metadata indexed by hostname."
  value = merge(
    [
      for o in module.vmdomain: o.vminfo
    ]...
  )
}
