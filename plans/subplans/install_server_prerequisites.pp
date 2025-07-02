# Installs the platform specific set of package dependencies for
# the openvox-server and openvoxdb packages if the installation
# parameters indicate we are install a pre-release package from
# artifacts.
#
# The pre-release packages are downloaded directly from the artifacts
# server and installed with rpm or dpkg, so no package dependencies
# are automatically installed by a higher layer like apt or dnf, which
# is why we need this subplan.
#
# @param targets The targets to install the packages on.
# @param package The name of the package to install. The subplan
#   will do nothing if the package does not match one needing
#   pre-requisite packages.
# @param params The parameters for the openvox installation.
#   If evaluation of params and defaults does not indicate that
#   the package is a pre-release package, then this plan will
#   do nothing.
# @param defaults The default parameters for the openvox installation.
plan kvm_automation_tooling::subplans::install_server_prerequisites(
  TargetSpec $targets,
  String $package,
  Kvm_automation_tooling::Openvox_install_params $params,
  Kvm_automation_tooling::Openvox_install_params $defaults,
) {
  $install_params = kvm_automation_tooling::validate_openvox_version_parameters(
    $defaults + $params,
  )

  $released = $install_params['openvox_released']

  if ($package in ['openvox-server', 'openvoxdb'] and !$released) {
    out::message("Installing pre-requisite packages for pre-release ${package}")
    # openvox-agent is already a pre-requisite for these packages,
    # so we expect the caller to have installed it already and can
    # rely on apply here.
    apply($targets) {
      case $facts['os']['family'] {
        'RedHat': {
          $packages = [
            'java-17-openjdk-headless',
            'net-tools',
            'procps-ng',
            'which',
          ]
        }
        'Debian': {
          $packages = [
            'openjdk-17-jre-headless',
            'net-tools',
            'procps',
          ]
        }
        default: {
          fail("Unsupported os: ${facts['os']}")
        }
      }
      package { $packages:
        ensure => installed,
      }
    }
  }
}
