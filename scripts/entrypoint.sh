#!/bin/bash

# VPN Setup
if [ -f "/config/wg0.conf" ]; then
    echo "--> Found wg0.conf. Starting WireGuard..."
    
    wg-quick up /config/wg0.conf
    
    # KILL SWITCH: Deny all non-local traffic that isn't going through wg0
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT
    iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT
else
    echo "!! No /config/wg0.conf found. Terminating container !!"
    exit 1
fi

echo "--> Applying Community Preferences..."
python3 /scripts/configure.py

# TODO: NAT-PMP port forwarding (Proton)

echo "--> Starting qBittorrent..."
exec /usr/bin/qbittorrent-nox --profile=/config
