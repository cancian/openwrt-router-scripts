#! /bin/sh
#
# Miredo client hook script for Linux/iproute2
# Copyright Denis-Courmont.
# Distributed under the terms of the GNU General Public License version 2.
# Modified by AndreL

# MTU for the tunnel interface
# (default: specified by the Teredo server, or 1280)
MTU=1472

# Destination route
# Teredo only: 2001::/32, Global IPv6: 2000::/3
ROUTE='2000::/3'

# Nothing to do with destroy event
[ "$STATE" != 'destroy' ] || exit 0

ip -6 route flush dev "$IFACE" 2>/dev/null
ip -6 address flush dev "$IFACE" 2>/dev/null
ip -6 link set dev "$IFACE" "$STATE" 2>/dev/null

if [ "$STATE" = 'up' ]; then
    ip link set dev "$IFACE" mtu "$MTU"

    ip -6 address add "${LLADDRESS}/64" dev "$IFACE"
    ip -6 address add "${ADDRESS}/32" dev "$IFACE"
        
    ip -6 route add "$ROUTE" from "${ADDRESS}" dev "$IFACE" proto static 2>/dev/null

    ACTION=ifupdate INTERFACE="${IFACE}" DEVICE="${IFACE}" /sbin/hotplug-call iface
fi

# This should be required when changing policy routing rules, but it
# seems to confuse certain kernels into removing our default route!
ip -6 route flush cache 2>/dev/null

exit 0
