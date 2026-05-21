#! /usr/bin/env bash

set -e

# PT_* variables are set by Bolt.
# shellcheck disable=SC2154
refresh_cache="${PT_refresh_package_cache}"
# shellcheck disable=SC2154
upgrade_packages="${PT_upgrade_packages}"

# Check if a command exists.
exists() {
  command -v "$1" > /dev/null 2>&1
}

refresh_package_cache() {
  if exists apt-get; then
    apt-get update
  elif exists dnf; then
    dnf clean all
    dnf makecache -y
  elif exists zypper; then
    zypper refresh
  else
    echo "No supported package manager found to refresh cache."
    exit 1
  fi
}

upgrade_all_packages() {
  if exists apt-get; then
    apt-get upgrade -y
  elif exists dnf; then
    dnf upgrade -y
  elif exists zypper; then
    zypper up -y
  else
    echo "No supported package manager found to upgrade packages."
    exit 1
  fi
}

if [ "${upgrade_packages}" == 'true' ]; then
  refresh_package_cache
  upgrade_all_packages
elif [ "${refresh_cache}" == 'true' ]; then
  refresh_package_cache
fi
