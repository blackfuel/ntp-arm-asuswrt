# ntp-arm-asuswrt


### HOWTO: Patch AsusWRT kernel to enable PPS
```
cd ~/asuswrt-merlin
patch -p2 -i ~/ntp-arm-asuswrt/asuswrt-arm-pps-enable.patch
```

### HOWTO: Compile NTP with support for NEMA + PPS
```
cd ~/ntp-arm-asuswrt
./ntp.sh
```
