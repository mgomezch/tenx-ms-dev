#!/usr/bin/env bash

set -e



tenx_config_dir="${HOME}/.config/tenx-vpn"
tenx_username_file="${tenx_config_dir}/username"
tenx_password_cipher='aes256'
tenx_password_file="${tenx_config_dir}/password.${tenx_password_cipher}"



function tenx-vpn-setup() {
  mkdir -p "${tenx_config_dir}" &&
  tenx-vpn-set-username &&
  tenx-vpn-set-password
}



function tenx-vpn-set-username() {
  printf 'Ten-X username: ' &&
  read 'tenx_username' &&
  printf '%s' "${tenx_username}" | tee "${tenx_username_file}" > '/dev/null'
}



function tenx-vpn-set-password() {
  (
    printf 'New Ten-X password: ' &&
    read -rs 'tenx_password' &&
    printf '\nCreating encrypted password file; ' &&
    openssl enc -e -"${tenx_password_cipher}" -a \
      <<< "${tenx_password}" \
      | tee "${tenx_password_file}" > '/dev/null'
  )
}



function tenx-vpn-connect() {
  sudo openconnect \
    --user="$(cat "${tenx_username_file}")" \
    --passwd-on-stdin \
    --authgroup=AUCTION-EMPL-ANYCONNECT \
    --verbose r2.auction.com \
    <<< "$(openssl enc -d -"${tenx_password_cipher}" -a < "${tenx_password_file}")"$'\nPUSH' \
    &&
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
