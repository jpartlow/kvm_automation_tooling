# This is a dev plan used to test kvm_automation_tooling in a clean
# environment. It goes one turtle down and nests libvirt within a VM,
# then sets up the ruby and terraform tooling needed to run module plans
# and checks out the module code.
#
# It is not intended to bootstrap the module on a workstation, since
# you would need the ruby environment already set up to run this plan.
# But the steps it takes are what you would need to prep a new
# workstation for the module.
#
# NOTE: The plan needs to be run as user that can ssh onto the VM with
# sudo privileges.
#
# ATM, intended for Ubuntu. Tested on Ubuntu 24.04:
# https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
#
# NOTE: For nested virtualization to work, the host must have the
# kvm_intel or kvm_amd kernel module loaded. This is not done by the plan.
# Running `cat /sys/module/kvm_intel/parameters/nested` should return "Y".
# In addition, the VM domain must have cpu mode set to host-passthrough.
# (If you are using the standup_cluster plan to create a vm to test with,
# the mode can be set using the cpu_mode parameter.)
#
# @param $dev_vm The target spec for the VM to be used for testing.
# @param $kvm_module_url The URL to the kvm_automation_tooling git
#   repository. This is used to check out the module code on the VM.
# @param $branch The branch to check out.
# @param $virbr0_network_prefix The three octet network prefix for the
#   new virbr0 network on the VM. (Distinguished from the host's virbr0
#   which will usually be 192.168.122.0/24).
plan kvm_automation_tooling::dev::prep_vm_for_module_testing(
  TargetSpec $dev_vm,
  String $kvm_module_url = 'https://github.com/jpartlow/kvm_automation_tooling.git',
  String $branch = 'main',
  String $virbr0_network_prefix = '192.168.123',
) {
  # I'm leaving this as script strings executed through run_command
  # rather than creating a bunch of little tasks so that the whole
  # setup process is easier to see.

  out::message('Install libvirt and add the run-as user to the libvirt group.')
  run_command(@(EOS), $dev_vm)
    set -e
    sudo apt update
    sudo apt install -y libvirt-daemon-system genisoimage
    sudo usermod -a -G libvirt "${USER}"
    # Even though selinux is disabled, this interferes with accessing the base image volume.
    # Probably this should be set to apparmor, but aa-complained shows nothing for /usr/sbin/libvirtd,
    # and there are no denials in /var/log/syslog, so I'm entirely sure what's going on.
    sudo sed -i -e 's/^#security_driver =.*$/security_driver = "none"/' '/etc/libvirt/qemu.conf'
    | EOS

  out::message('Rebooting the VM to apply group changes.')
  run_command('sudo reboot', $dev_vm)
  # Wait a few seconds for the VM to have shutdown, otherwise the
  # wait_until_available function may successfully connect before the
  # reboot has really begun, and the next command may fail to connect
  # during the reboot...
  ctrl::sleep(5)
  wait_until_available($dev_vm)

  # This step wouldn't be necessary setting up a new workstation.
  # It's here to distinguish the VM virbr0 network from the host's
  # virbr0 network.
  out::message('Reset the default network to use the provided prefix.')
  run_task('kvm_automation_tooling::dev_reset_libvirt_network', $dev_vm,
    'name'                    => 'default',
    'original_network_prefix' => '192.168.122',
    'new_network_prefix'      => $virbr0_network_prefix,
  )

  out::message('Install terraform.')
  run_command(@(EOS), $dev_vm)
    # From https://developer.hashicorp.com/terraform/install
    wget -O - "https://apt.releases.hashicorp.com/gpg" | \
      sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    set -e
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
      sudo tee "/etc/apt/sources.list.d/hashicorp.list"
    sudo apt update && sudo apt install -y terraform
    | EOS

  out::message('Install ruby and packages required for rubygem native builds.')
  run_command(@(EOS), $dev_vm)
    sudo apt install -y ruby ruby-bundler libvirt-dev ruby-dev build-essential
    | EOS

  out::message('Checkout an instance of kvm_automation_tooling, install the gem bundle and checkout the supporting Puppet modules.')
  run_command(@("EOS"), $dev_vm)
    set -e
    if ! [ -d kvm_automation_tooling ]; then
      git clone "${kvm_module_url}"
    fi
    cd kvm_automation_tooling
    git checkout "${branch}"
    mkdir -p vendor/bundle
    bundle config set --local path vendor/bundle
    bundle install
    bundle exec bolt module install
    | EOS

  # Requires the ruby environment and gem bundle from the previous steps...
  out::message('Create a libvirt directory pool for the default images.')
  run_command(@(EOS), $dev_vm)
    set -e
    cd kvm_automation_tooling
    bundle exec bolt task run kvm_automation_tooling::create_libvirt_image_pool \
      --targets=localhost name=default path='/var/lib/libvirt/images'
    | EOS

  $ssh_key_file="\${HOME}/.ssh/ssh-id-test"

  out::message('Generate an ssh key pair without passphrase on the VM for the test user.')
  run_command(@("EOS"), $dev_vm)
    if ! [ -f "${ssh_key_file}" ]; then
      ssh-keygen -q -t ed25519 -N "" -f "${ssh_key_file}"
    fi
    | EOS

  out::message('Standup a test cluster using the VM libvirt.')
  run_command(@("EOS"), $dev_vm,)
    set -e
    cd kvm_automation_tooling
    cat > standup_cluster_params.json <<EOF
    {
      "cluster_name": "test",
      "network_addresses": "192.168.200.0/24",
      "ssh_public_key_path": "${ssh_key_file}.pub",
      "os": "ubuntu",
      "os_version": "2404",
      "os_arch": "x86_64",
      "architecture": "singular",
      "agents": 1,
      "primary_cpus": 2,
      "primary_mem_mb": 4096,
      "primary_disk_gb": 5,
      "agent_cpus": 1,
      "agent_mem_mb": 512,
      "agent_disk_gb": 5
    }
    EOF
    bundle exec bolt plan run kvm_automation_tooling::standup_cluster --params @standup_cluster_params.json
    | EOS
}
