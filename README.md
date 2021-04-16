Archerry
========

<img
    align="right"
    width="150"
    height="150"
    src="https://github.com/anryoshi/archerry/blob/master/assets/archerry_logo.svg"
    alt="archerry logo">

*Arch* Linux on Rasb*erry* Pi

This repository contains instruction and scripts to configure
your Raspberry Pi to work with Arch Linux ARM installation
and expose network on the USB Type-C port

This allows you work with you to power and connect over network
from your iPad Pro/Air simultaneously

[Original idea](https://youtu.be/IR6sDcKo3V8) by [Tech Craft](https://twitter.com/tech_crafted)

---

Installation
------------
### Prerequisites
- Raspberry PI with aarch64 support. That means ARMv8 instruction set. Supported ISA could be checked in [specification](https://en.wikipedia.org/wiki/Raspberry_Pi#Specifications) of model
- SD card. Recommended minimum size 16Gb 
- Another Linux host (virtual machine, e.g VirtualBox, could work too with USB passthrough configured properly) for creating initial bootable card. Of course hub or builtin port for SD required too
- Availability to connect Raspberry Pi to Ethernet Network
  or dedicated workspace (monitor and keyboard) for it

### Step-by-step instruction

#### Step 1: Prepare initial boot disk with vanilla Arch Linux ARM
Image could be created according [instruction](https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4)
or with [script](https://github.com/anryoshi/archerry/tree/master/scripts/01_prepare_initial_disk.sh)

**IMPORTANT**: this script requires `sudo` and works in not interactive manner.
Be careful specifying device for formating, you could lose all your data or harm your system

*Result*: bootable SD card with vanilla Arch Linux ARM. DHCP for Ethernet should be enabled and default user `alarm` should exist. `sshd` should be enabled as well.

#### Step 2: Migrate to Raspberry Pi Linux kernel
> **Why upstream kernel should be replaced?**
>
> The short answer is *bugs*. There are some bugs in upstream kernel (especially for RPi4 8Gb)
> related to peripherals and interfaces (e.g. USB), and the simplest way to get rid of them
> is to switch to supported and tested version of kernel provided by RPi developers.
> If initial distribution of Arch Linux ARM will switch to the supported aarch64 kernel
> this step will not be needed in future.

[Script](https://github.com/anryoshi/archerry/tree/master/scripts/02_migrate_to_rpi_kernel.sh)
could be used for non-interactive configuration. Requires `sudo` and reboot host at the end.

If you want to do steps by hand, always rember to modify *fstab* file accordingly, otherwise machine will not boot.

*Result*: Pi now runs new Linux kernel

#### Step 3: Configuring wireless networks
> Because solution to share iPad connection to the Internet over Ethernet was not found
> the main solution of connecting Pi to network while using with tablet will be wireless network

[Script](https://github.com/anryoshi/archerry/tree/master/scripts/03_configure_wireless_network.sh)
could be used as *interactive* tool for configuring.

It adds only one network to the `wpa_supplicant` configuration. Additional networks could be added with `wpa_cli`.

*Result*: Pi could connect to specified WiFi network automatically

#### Step 4: Configuring USB Type-C port as network interface
[Script](https://github.com/anryoshi/archerry/tree/master/scripts/04_configure_usb_type_c.sh)
could be used for non-interactive configuration.

*Result*: special daemon configures `usb0` device each boot allowing to use it as network
interface, mDNS provides name resolution of RPi host for iPad
#### Step 5: Connecting Pi to iPad and post installation configuration
After previous steps it is finally possible to access Raspberry Pi from iPad
using `<raspberry_pi_hostname>.local` name. If all configured properly iPad should show Ethernet connection in its settings with `ipv4 : 169.254.*.*`

##### Post installation configuration steps:
1. In most cases `base-devel` package is required by Arch Linux users
2. Create new user
3. Configuring `sudo`
4. Installing AUR helper (e.g. [yay](https://github.com/Jguer/yay))


Image creation
--------------
After creation of configured environment for specific device it's good idea to save it as **image** for easy redeploying in future.

1. Creation of new image file from device
    ```sh
    # probably requires sudo on your platform
    dd bs=1M if=/dev/<sd_device> of=<image_name>.img 
    ```
2. Shrinking it to actual size - [PiShrink](https://github.com/Drewsif/PiShrink) is a good solution for this task


After redeploying of image the process of expanding volume required.
```sh
fdisk /dev/<sd_device> <<EOF
p
d
<root_volume_number>
n
p
<root_volume_number>
p
w
EOF

resize2fs /dev/<root_volume>
```

TODO
----

- [ ] Share pre-built images

