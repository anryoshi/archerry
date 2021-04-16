#!/bin/bash -e

read -p "Provide SSID: " network_ssid
if [ -z "$network_ssid" ]; then
  printf "SSID could not be empty\n" >&2
  exit 1
fi

read -p "Provide passphrase: " network_psk
if [ -z "$network_psk" ]; then
  printf "Passphrase could not be empty\n" >&2
  exit 1
fi

printf "Creating new wpa_supplicant configuration\n"
tee /etc/wpa_supplicant/wpa_supplicant-wlan0.conf <<EOF
ctrl_interface=/run/wpa_supplicant
update_config=1
network={
  ssid="$network_ssid"
  psk="$network_psk"
}
EOF

printf "Writing systemd-network configuration\n"
tee /etc/systemd/network/25-wireless.network <<EOF
[Match]
Name=wlan0

[Network]
DHCP=ipv4
EOF

printf "Restarting daemons\n"
systemctl start wpa_supplicant@wlan0
systemctl enable wpa_supplicant@wlan0
systemctl restart systemd-networkd
