# Transforms the array of vm specifications received by the plan into
# a map of terraform objects (hashes) keyed by a unique
# "$role.$hostname.$platform" string with os image parameters injected.
#
# The hostname values are generated as "${cluster_id}-${role}-${index}"
# where the index is the 1-based index of the vm in the set.
#
# See the spec/functions/generate_terraform_vm_spec_set_spec.rb for
# a concrete example.
#
# Missing values for cpus, mem_mb, disk_gb and cpu_mode are provided
# by terraform modules/vm defaults.
#
# @param cluster_id The identifier for the cluster.
# @param vm_specs The array of vm specifications received by the plan.
# @param image_results The results of each manage_base_image_volume
#   plan run for each platform in the specs.
# @return A map of terraform objects (hashes) representing vm
#   parameters for the terraform/modules/vm module, keyed by unique
#   hostname.
function kvm_automation_tooling::generate_terraform_vm_spec_set(
  String $cluster_id,
  Array[Kvm_automation_tooling::Vm_spec] $vm_specs,
  Array[Hash] $image_results,
) >> Hash[String, Hash] {
  $roles = $vm_specs.map |$spec| { $spec['role'] }.unique()
  $roles.reduce({}) |$map,$role| {
    $specs_in_role = $vm_specs.filter |$spec| { $spec['role'] == $role }
    $expanded_specs = $specs_in_role.reduce({}) |$role_map, $spec| {
      $platform = kvm_automation_tooling::platform($spec['os'])
      $os_name = dig($spec, 'os', 'name')
      $role = $spec['role']
      $count = $spec['count'] =~ Undef ? {
        true    => 1,
        default => $spec['count'],
      }
      $image_result = $image_results.filter |$i| {
        $i['platform'] == $platform
      }[0]

      $common = $spec.filter |$k, $_v| {
        ['cpus', 'mem_mb', 'disk_gb', 'cpu_mode'].any |$i| {
          $k == $i
        }
      } + {
        'base_volume_name' => $image_result['base_volume_name'],
        'pool_name'        => $image_result['pool_name'],
        'os'               => $os_name,
      }

      $last_index = $role_map.size()
      $role_map + Integer[1, $count].reduce({}) |$m, $i| {
        $index = $last_index + $i
        $hostname = "${cluster_id}-${role}-${index}"
        $m + {
          "${role}.${hostname}.${platform}" => $common
        }
      }
    }
    $map + $expanded_specs
  }
}
