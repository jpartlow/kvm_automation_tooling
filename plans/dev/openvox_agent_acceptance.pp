# Dev plan to run openvox-agent acceptance tests from a runner VM
# on a set of agent vms.
#
# This plan assumes that something has already installed the
# version of openvox-agent we want to test on the agent VMs.
# It does not use beaker-puppet installation utilities, since
# they can't handle agent packages outside of the default
# puppet-agent package names and repositories.
#
# @param runner The target spec for the runner VM that will run
#   the oenvox-agent acceptance tests.
# @param agents The target spec for the agent VMs that will be
#   teste by the openvox-agent acceptance tests.
# @param openvox_agent_url The url of the openvox-agent git
#   repostory.
# @param branch The branch of the openvox-agent git repository
#   to chckout.
# @param user The user ssh account on the VMs where openv-agent
#   will be checked out and beaker run.
plan kvm_automation_tooling::dev::openvox_agent_acceptance(
  TargetSpec $runner,
  TargetSpec $agents,
  String $openvox_agent_url = 'https://github.com/OpenVoxProject/openvox-agent',
  String $branch = 'main',
  String $user = system::env('USER'),
) {
  out::message('Install ruby and packages required for rubygem native builds.')
  run_command(@(EOS), $runner)
    sudo apt install -y ruby ruby-bundler ruby-dev build-essential
    | EOS

  out::message('Checkout an instance of openvox-agent and install the gem bundle.')
  run_command(@("EOS"), $runner, '_run_as' => $user)
    set -e
    if ! [ -d openvox-agent ]; then
      git clone "${openvox_agent_url}"
    fi
    cd openvox-agent/acceptance
    git checkout "${branch}"
    mkdir -p vendor/bundle
    bundle config set --local path vendor/bundle
    bundle install
    | EOS

  out::message('Create a hosts.yaml file for beaker.')
  $host_yaml = '/tmp/openvox_agents-beaker-hosts.yaml'
  run_plan('kvm_automation_tooling::dev::generate_beaker_hosts_file', {
    'hosts'      => $agents,
    'hosts_yaml' => $host_yaml,
  })
  upload_file(
    $host_yaml,
    "/home/${user}/openvox-agent/acceptance/hosts.yaml",
    $runner,
  )

  out::message('Run beaker.')
  run_command(@(EOS), $runner, '_run_as' => $user)
    set -e
    cd openvox-agent/acceptance
    # Get rid of the post_suite defined in the repo's
    # config/aio/options.rb included from the .beaker.yml defaults.
    # The type value is necessary for the configure_type_defaults_on()
    # method to work properly as it will default to 'pe' otherwise.
    echo '{type:"aio"}' > local_options.rb
    cat > configure_type_defaults.rb <<EOF
    test_name('configure root ssh environment path') do
      configure_type_defaults_on(agents)
    end
    EOF
    bundle exec beaker init --hosts hosts.yaml --preserve-hosts always \
      --keyfile ~/.ssh/id_ed25519 --pre-suite configure_type_defaults.rb \
      --tests tests --options_file local_options.rb
    # The provision step is still needed here, see notes in the
    # beaker-hosts.yaml.epp template...
    bundle exec beaker provision
    bundle exec beaker exec
    | EOS
}
