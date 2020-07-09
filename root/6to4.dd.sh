#!/bin/bash
##########
## 6to4 ##
##########
WANIP=$(ip addr show dev eth1 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
if [ -n "$WANIP" ]
then
  V6IP=$(printf '2002:%02x%02x:%02x%02x::1/64' $(echo $WANIP | tr . ' '))
  ip tunnel add tun6to4 mode sit remote any local $WANIP
  ip link set tun6to4 up
  ip -6 route add 2000::/3 via ::192.88.99.1
  ip addr add $V6IP dev br0
fi
