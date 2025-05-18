# Check whether ip addresses returned by the terraform apply
# are all valid ipv4 addresses.
#
# A Bolt::Target.uri needs an ipv4 address when we resolve references.
#
# @param terraform_apply_result A Hash returned from the
#   terraform::apply plan (this is the hash from a parsed
#   `terraform output -json` result).
# @return Boolean true if all ip addresses are valid ipv4 addresses,
#   false if any are missing or ipv6.
function kvm_automation_tooling::validate_vm_ip_addresses(
  Hash $terraform_apply_result,
) >> Boolean {
    $ip_addresses = $terraform_apply_result.dig('vm_ip_addresses', 'value')
    if $ip_addresses !~ Hash[String,String] {
      log::warn(@("EOS"/L))
        Terraform apply did not return a valid hash of ip \
        addresses indexed by role.hostname:
        ${terraform_apply_result}
        |- EOS
      $valid_addresses = false
    } else {
      out::message("VM IP addresses: ${stdlib::to_json_pretty($ip_addresses)}")
      $addresses = $ip_addresses.values()
      $all_addresses_valid = $addresses.all |$ip| { $ip =~ Stdlib::Ip::Address::V4 }
      if !$addresses.empty() and $all_addresses_valid {
        $valid_addresses = true
      } else {
        log::warn('Some hosts missing valid IPv4 addresses; refreshing state.')
        $valid_addresses = false
      }
    }
    $valid_addresses
}
