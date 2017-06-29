#!/usr/bin/env bash

set -e


config_dir="${HOME}/.config/tenx-vpn"
keyring_key='tenx'
keyring_label='Ten-X VPN password (r2.auction.com)'
keyring_value='r2.auction.com'
password_cipher='aes256'
password_file="${config_dir}/password.${password_cipher}"
username_file="${config_dir}/username"


use_keyring="$(command -v secret-tool > '/dev/null' 2>&1; echo "$?")"


function tenx-vpn-setup() {
  mkdir -p "${config_dir}" &&
  tenx-vpn-set-username &&
  tenx-vpn-set-password
}


function tenx-vpn-set-username() {
  printf 'Ten-X username: ' &&
  read 'username' &&
  printf '%s' "${username}" | tee "${username_file}" > '/dev/null'
}


function tenx-vpn-set-password() {
  (
    if [[ "${use_keyring}" ]]
    then
      echo 'Saving new Ten-X password in keyring' &&
      secret-tool store \
        --label="${keyring_label}" \
        "${keyring_key}" \
        "${keyring_value}"
    else
      printf 'Saving new Ten-X password in encrypted file\nPassword: ' &&
      read -rs 'password' &&
      printf '\nCreating encrypted password file; ' &&
      openssl enc -e -"${password_cipher}" -a \
        <<< "${password}" \
        | tee "${password_file}" > '/dev/null'
    fi
  )
}


function tenx-vpn-connect() {
  (
    if [[ ! -z "${use_keyring}" ]]
    then
      password="$(
        secret-tool lookup \
          "${keyring_key}" \
          "${keyring_value}"
      )"
    else
      password="$(
        openssl enc -d \
          -"${password_cipher}" \
          -a \
          < "${password_file}"
      )"
    fi &&
    sudo openconnect \
      --user="$(cat "${username_file}")" \
      --passwd-on-stdin \
      --authgroup=AUCTION-EMPL-ANYCONNECT \
      --verbose r2.auction.com \
      <<< "${password}"$'\nPUSH' \
  ) &&
  sudo ip route add '10.0.0.0/8' dev 'tun0' &&
  sudo route del default 'tun0'
}


case "${1}" in
  ('setup') tenx-vpn-setup ;;
  ('set-username') tenx-vpn-set-username ;;
  ('set-password') tenx-vpn-set-password ;;
  ('connect') tenx-vpn-connect ;;
  (*) echo "Usage: $0 {setup|set-username|set-password|connect}"
esac
