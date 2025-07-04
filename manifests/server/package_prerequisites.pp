# Ensures package dependencies for openvox-server or openvoxdb.
#
# This class can be used for cases where openvox-server or openvoxdb
# packages are downloaded and installed directly, bypassing dependency
# handling by package managers like apt or dnf.
class kvm_automation_tooling::server::package_prerequisites () {
  notify { 'osfacts':
    message => "${facts['os']['family']}-${facts['os']['release']['major']}",
  }
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
      $common = [
        'net-tools',
        'procps',
      ]
      case $facts['os']['release']['major'] {
        '10': {
          $packages = $common + ['openjdk-11-jre-headless']
        }
        '13': {
          $packages = $common + ['openjdk-21-jre-headless']
        }
        default: {
          $packages = $common + ['openjdk-17-jre-headless']
        }
      }
    }
    default: {
      fail("Unsupported os: ${facts['os']}")
    }
  }
  package { $packages:
    ensure => present,
  }
}
