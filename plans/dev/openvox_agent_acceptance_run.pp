# Dev plan to run openvox-agent acceptance tests from a runner VM
# on a set of agent vms.
plan kvm_automation_tooling::dev::openvox_agent_acceptance(
  TargetSpec $runner,
  TargetSpec $agents,
  String $openvox_agent_url = 'https://github.com/OpenVoxAgent/openvox-agent',
  String $branch = 'main',
) {
  out::message('Install ruby and packages required for rubygem native builds.')
  run_command(@(EOS), $runner)
    sudo apt install -y ruby ruby-bundler ruby-dev build-essential
    | EOS

  out::message('Checkout an instance of openvox-agent and install the gem bundle.')
  run_command(@("EOS"), $runner)
    set -e
    if ! [ -d openvox-agent ]; then
      git clone "${openvox_agent_url}"
    fi
    cd openvox-agent
    git checkout "${branch}"
    mkdir -p vendor/bundle
    bundle config set --local path vendor/bundle
    bundle install
    | EOS

  $ssh_key_file="\${HOME}/.ssh/ssh-id-test"

  out::message('Generate an ssh key pair without passphrase on the VM for the test user.')
  run_command(@("EOS"), $runner)
    if ! [ -f "${ssh_key_file}" ]; then
      ssh-keygen -q -t ed25519 -N "" -f "${ssh_key_file}"
    fi
    | EOS
}
