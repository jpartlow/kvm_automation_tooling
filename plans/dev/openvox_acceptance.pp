# Dev plan to run an openvox agent, server or db Beaker acceptance
# test suite from a runner VM against a set of subject test vms.
#
# This plan assumes that something has already installed the
# version of openvox-agent, openvox-server and openvoxdb we want to
# test on the agent VMs. It does not use beaker-puppet installation
# utilities, since they can't handle packages outside of the default
# Perforce package names and repositories.
#
# @param runner The target spec for the runner VM that will run
#   the acceptance tests.
# @param subjects The target spec for the VMs that will be
#   tested by the acceptance tests.
# @param project The name of the project to test.
# @param namespace The Github namespace of the project to test.
# @param branch The branch of the repository to checkout.
# @param user The user ssh account to access the runner target for
#   running Beaker.
# @param subject_ssh_key The SSH key Beaker will use to reach
#   the subject targets. (The default assumes the key generated
#   by kvm_automation_tooling::standup_cluster::setup_cluster_ssh=true.
#   Also note that setup_cluster_root_ssh should usually be true
#   for Beaker to be able to test the subjects correctly.)
plan kvm_automation_tooling::dev::openvox_acceptance(
  TargetSpec $runner,
  TargetSpec $subjects,
  Enum[openvox-agent,openvox-server,openvoxdb] $project = 'openvox-agent',
  String $namespace = 'OpenVoxProject',
  String $branch = 'main',
  String $user = system::env('USER'),
  String $subject_ssh_key = "/home/${user}/.ssh/id_ed25519",
) {
  $project_url = "https://github.com/${namespace}/${project}.git"
  $suite_defaults = {
    'openvox-agent' => {
      'pre-suite' => [
        'pre-suite/configure_type_defaults.rb',
      ],
      'tests' => [
        'tests',
      ],
    },
    'openvox-server' => {
      'pre-suite' => [
        'pre-suite',
      ],
      'tests' => [
        'tests',
      ],
    },
  }

  out::message('Install ruby and packages required for rubygem native builds.')
  $runner_target = get_target($runner)
  run_plan('facts', 'targets' => $runner_target)
  if ($runner_target.facts()['aio_agent_version'] == undef) {
    apply_prep($runner_target)
  }
  apply($runner_target) {
    $common_packages = [
      'ruby',
      'git',
    ]
    case $facts['os']['family'] {
      'Debian': {
        $packages = [
          'build-essential',
          'ruby-bundler',
          'ruby-dev',
        ]
      }
      'RedHat': {
        $packages = [
          'redhat-rpm-config', # for building bcrypt_pbkdf gem
          'ruby-devel',
          'rubygem-bundler',
          'make',
          'gcc',
        ]
      }
      default: {
        fail("Unsupported os: ${facts['os']}")
      }
    }
    package { $packages + $common_packages:
      ensure => installed,
    }
  }

  out::message("Checkout an instance of ${project} and install the gem bundle.")
  run_command(@("EOS"), $runner_target, '_run_as' => $user)
    set -e
    if ! [ -d ${project} ]; then
      git clone "${project_url}"
    fi
    cd ${project}/acceptance
    git checkout "${branch}"
    bundle config set --local path vendor/bundle
    bundle install
    | EOS

  out::message('Create a hosts.yaml file for beaker.')
  $host_yaml = '/tmp/openvox-beaker-hosts.yaml'
  run_plan('kvm_automation_tooling::dev::generate_beaker_hosts_file', {
    'hosts'      => $subjects,
    'hosts_yaml' => $host_yaml,
  })
  upload_file(
    $host_yaml,
    "/home/${user}/${project}/acceptance/hosts.yaml",
    $runner_target,
  )

  out::message('Run beaker.')
  $pre_suite = $suite_defaults[$project]['pre-suite'].join(',')
  $tests = $suite_defaults[$project]['tests'].join(',')
  run_command(@("EOS"), $runner_target, '_run_as' => $user)
    set -e
    cd ${project}/acceptance

    bundle exec beaker init --hosts hosts.yaml \
      --preserve-hosts always --keyfile ${subject_ssh_key} \
      --pre-suite ${pre_suite} \
      --tests ${tests}
    # The provision step is still needed here, see notes in the
    # beaker-hosts.yaml.epp template...
    bundle exec beaker provision
    bundle exec beaker exec
    | EOS
}
