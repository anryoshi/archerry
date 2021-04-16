#!/bin/bash

hostnamectl set-hostname "${DESIRED_HOSTNAME}"

# Installing mDNS
pacman -S avahi
systemctl start avahi-daemon
systemctl enable avahi-daemon

# Enabling Device Tree overlay for dwc2
echo "dtoverlay=dwc2" | tee -a /boot/config.txt

# Creating daemon script
tee /root/usb0.sh << EOF
#!/bin/bash

set -e

modprobe libcomposite
cd /sys/kernel/config/usb_gadget/
mkdir -p pi4
cd pi4
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2
echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol
mkdir -p strings/0x409
echo "fedcba9876543211" > strings/0x409/serialnumber
echo "Ben Hardill" > strings/0x409/manufacturer
echo "PI4 USB Device" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "Config 1: ECM network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower
# Add functions here
# see gadget configurations below
# End functions
mkdir -p functions/ecm.usb0
HOST="00:dc:c8:f7:75:14" # "HostPC"
SELF="00:dd:dc:eb:6d:a1" # "BadUSB"
echo $HOST > functions/ecm.usb0/host_addr
echo $SELF > functions/ecm.usb0/dev_addr
ln -s functions/ecm.usb0 configs/c.1/
udevadm settle -t 5 || :
ls /sys/class/udc > UDC
ip link set usb0 up
EOF

chmod +x /root/usb0.sh

# Creating systemd unit for daemon
tee /etc/systemd/system/usb0.service << EOF
[Unit]
Description=Run usb0.sh

[Service]
Type=oneshot
ExecStart=/root/usb0.sh

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable usb0

reboot
