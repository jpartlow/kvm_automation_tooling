#! /usr/bin/env bash

set -e

# PT_* variables are set by Bolt.
# shellcheck disable=SC2154
user="${PT_user}"
# shellcheck disable=SC2154
ssh_public_key="${PT_ssh_public_key}"

if [ "${user}" == "root" ]; then
  ssh_dir="/root/.ssh"
else
  ssh_dir="/home/${user}/.ssh"
fi

# Create the .ssh directory if it doesn't exist
if [ ! -e "${ssh_dir}" ]; then
  mkdir --mode=700 "${ssh_dir}"
  chown "${user}:${user}" "${ssh_dir}"
fi

authorized_keys_path="${ssh_dir}/authorized_keys"
echo "${ssh_public_key}" >> "${authorized_keys_path}"
chmod 600 "${authorized_keys_path}"
chown "${user}:${user}" "${authorized_keys_path}"
