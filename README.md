If the SD card fails, connect the serial and netboot the espressoflex
When changing networks, there are a few things that will have to be updated everytime. 

/settings/wpa_supplicant.conf
/settings/iptables.rules

the wireless dhcp and all other network setup and settings are in /etc/systemd/networkd/blah. specifically DHCP for wlp0s0 is done by 25-wireless.network. bridge configuration is done by br0.netdev and br0.network. addition of interfaces to the bridge is done by the other $interface.network files.
