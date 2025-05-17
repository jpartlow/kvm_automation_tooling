# Expands the compact vm specification used by the plan into a
# map of terraform objects (hashes) keyed by unique hostname,
# that map one to one with each vm we want terraform to create.
#
# See the spec/functions/generate_terraform_vm_spec_set_spec.rb for
# a concrete example.
#
# Missing values for cpus, mem_mb, disk_gb and cpu_mode are provided
# by terraform modules/vm defaults.
#
# @param $cluster_id The unique identifier for the cluster.
# @param $vm_specs The compact vm specification used by the plan.
# @param $image_results The results of each manage_base_image_volume
#   plan run for each platform in the specs.
function kvm_automation_tooling::generate_terraform_vm_spec_set(
  String $cluster_id,
  Array[Kvm_automation_tooling::Vm_spec] $vm_specs,
  Array[Hash] $image_results,
) >> Hash[String, Hash] {
  $vm_specs.reduce({}) |$map, $spec| {
    $platform = kvm_automation_tooling::platform($spec['os'])
    $os_name = dig($spec, 'os', 'name')
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

    $map + Integer[1, $count].reduce({}) |$m, $i| {
      $m + {
        "${cluster_id}-${spec['role']}-${i}" => $common
      }
    }
  }
}
