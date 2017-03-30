# ntp-arm-asuswrt

### HOWTO: Compile an NTP server with NEMA/GPS + PPS support for AsusWRT firmware
```
cd
git clone https://github.com/blackfuel/ntp-arm-asuswrt.git
cd ntp-arm-asuswrt
./ntp.sh
```

### HOWTO: Patch AsusWRT kernel to enable PPS over USB
```
cd ~/asuswrt-merlin
patch -p2 -i ~/ntp-arm-asuswrt/asuswrt-arm-pps-enable.patch
```
