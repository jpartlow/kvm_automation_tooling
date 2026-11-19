# Ensure that the base image is downloaded for the given platform and
# imported into libvirt as a volume. Ensure that a libvirt pool for
# platform images based on this volume is created as well.
#
# @param os_spec The operating system specification for the base
#   image.
# @param image_download_dir The directory where the base image will be
#   downloaded and stored.
# @param runner_platform The platform string of the local runner host
#   (as per kvm_automation_tooling::platform() output...)
# @param in_gha Whether this is running in GitHub Actions.
#   Controls whether to run virt-customize workarounds for platforms
#   having issues running within in gha. Usually determined
#   automatically.
plan kvm_automation_tooling::subplans::manage_base_image_volume(
  Kvm_automation_tooling::Os_spec $os_spec,
  String $image_download_dir,
  String $runner_platform,
  Boolean $in_gha = (system::env('GITHUB_ACTIONS') == 'true'),
) {
  $platform = kvm_automation_tooling::platform($os_spec)

  run_command("mkdir -p ${image_download_dir}", 'localhost')

  # Download and import base image.
  $base_image_url = kvm_automation_tooling::get_image_url($os_spec)
  $base_image_name = $base_image_url.split('/')[-1]
  $base_image_path = "${image_download_dir}/${base_image_name}"
  run_task('kvm_automation_tooling::download_image', 'localhost',
    'image_url'    => $base_image_url,
    'download_dir' => $image_download_dir,
  )

  # Conditionally perform wonderful special case hacks related to
  # traumas discussed in the following structure:
  $vc_systemd_conf_d = '/etc/systemd/system.conf.d'
  $vc_device_timeout_conf = "${vc_systemd_conf_d}/99-device-timeout.conf"
  $virt_customizations_table = [
    # In GHA x86_64 runners, ubuntu 26.04 arm images are hitting
    # timeouts waiting for the boot/uefi disk devices to be available,
    # so this boosts the systemd device timeout from the default of 90s
    # to 300s.
    {
      'case' => $in_gha,
      'guests' => {
        'ubuntu-2604-arm64' => [
          "--mkdir '${vc_systemd_conf_d}'",
          "--write '${vc_device_timeout_conf}:[Manager]'",
          "--append '${vc_device_timeout_conf}:DefaultDeviceTimeoutSec=300'",
        ],
      },
    },
    # Ubuntu 26.04 runners have a newer EDK2 (EFI Development Kit II)
    # firmware. When it interacts with the el8 (rocky/almalinux)
    # images hijinx ensue, despite secureboot being disabled.
    # Symptoms of said hijinx (from alma8 console logs, rocky8 is less
    # forthcoming):
    #
    #   UEFI firmware (version 2025.11-3ubuntu7.3 built at 15:40:26 on Sep 23 2026)
    #   BdsDxe: loading Boot0002 "UEFI Misc Device" from PciRoot(0x0)/Pci(0x1,0x2)/Pci(0x0,0x0)
    #   BdsDxe: starting Boot0002 "UEFI Misc Device" from PciRoot(0x0)/Pci(0x1,0x2)/Pci(0x0,0x0)
    #   Invalid call dxe_update_mem_attrs(addr:0x1320AA400-0x1320C63FF, size:0x1C000, +rx, -w)
    #    addr is not page aligned
    #
    # If I'm understanding correctly from a gemini summary, the
    # following players are involved in said hijinx:
    #
    # 1. The UEFI Firmware (qemu-efi-aarch64 / EDK2): Lives on the
    #    Ubuntu 26.04 host (built in 2026).
    # 2. shim (BOOTAA64.EFI / shimaa64.efi): Lives inside the
    #    AlmaLinux 8 guest image (updated to Shim 16.1 in 2026 for the
    #    Microsoft 2023 certificate rollout).
    # 3. GRUB (grubaa64.efi): Lives inside the AlmaLinux 8 guest image
    #    (compiled with an older RHEL 8 toolchain/linker layout).
    #
    # The runner's firmware interacts with the shim to run the
    # bootloader (grub). 24.04 was lenient in not enforcing page
    # alignment for the portable executable (the bootloader in this
    # case, if I'm following along). 26.04 is strict and halts because
    # the old grub efi doesn't match its expectations.
    #
    # So we're bypassing the shim by copying grub in it's place
    # to be booted directly.
    {
      'case' => ($runner_platform == 'ubuntu-2604-amd64'),
      'guests' => {
        'almalinux-8-aarch64' => [
          "--copy '/boot/efi/EFI/almalinux/grubaa64.efi:/boot/efi/EFI/BOOT/BOOTAA64.EFI'",
        ],
        'rocky-8-aarch64' => [
          "--copy '/boot/efi/EFI/rocky/grubaa64.efi:/boot/efi/EFI/BOOT/BOOTAA64.EFI'",
        ],
      },
    },
  ]
  $virt_customizations_table.each |$entry| {
    if $entry['case'] {
      $virt_customizations = $entry['guests'][$platform]
      if $virt_customizations !~ Undef {
        $command = "virt-customize -a ${base_image_path} --no-network ${virt_customizations.join(' ')}"
        run_command($command, 'localhost',
          '_run_as' => 'root',
          # For debugging virt-customize (this is verbose).
          '_env_vars' => {
            'LIBGUESTFS_DEBUG' => 1,
            'LIBGUESTFS_TRACE' => 1,
          },
        )
      }
    }
  }

  run_task('kvm_automation_tooling::import_libvirt_volume', 'localhost',
    'image_path'  => $base_image_path,
    'volume_name' => $base_image_name,
  )

  # Ensure platform image pool exists.
  $pool_name = "${platform}.pool"
  # TODO: This should probably just be called 'pool_dir'. Or I should
  #       elliminate the distinction between the two and drop '.pool'.
  $pool_path = $platform
  run_task('kvm_automation_tooling::create_libvirt_image_pool', 'localhost',
    'name' => $pool_name,
    'path' => $pool_path,
  )

  $result = {
    'platform'         => $platform,
    'base_image_url'   => $base_image_url,
    'base_volume_name' => $base_image_name,
    'pool_name'        => $pool_name,
    'pool_path'        => $pool_path,
  }
  return $result
}
