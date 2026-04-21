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
    $vm_info = $terraform_apply_result.dig('vm_info', 'value')
    if $vm_info !~ Hash[String,Hash[String,Variant[String,Array[String]]]] {
      log::warn(@("EOS"/L))
        Terraform apply did not return a valid hash of ip \
        addresses indexed by role.hostname:
        ${terraform_apply_result}
        |- EOS
      $valid_addresses = false
    } else {
      out::message("VM Info: ${stdlib::to_json_pretty($vm_info)}")
      $ip_addresses = $vm_info.values().map |$info| {
        $info['ip_addresses']
      }.flatten()
      $all_addresses_valid = $ip_addresses.all |$ip| { $ip =~ Stdlib::Ip::Address::V4 }
      if !$ip_addresses.empty() and $all_addresses_valid {
        $valid_addresses = true
      } else {
        log::warn('Some hosts missing valid IPv4 addresses; refreshing state.')
        $valid_addresses = false
      }
    }
    $valid_addresses
}
