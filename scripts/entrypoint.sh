#!/bin/bash

# VPN Setup
if [ -f "/config/wg0.conf" ]; then
  echo "--> Found wg0.conf. Starting WireGuard..."

  VPN_DNS=$(grep -i '^[[:space:]]*DNS[[:space:]]*=' /config/wg0.conf | cut -d '=' -f 2 | tr -d ' ' | head -n 1)
  grep -v -i '^[[:space:]]*DNS[[:space:]]*=' /config/wg0.conf >/etc/wireguard/wg0.conf

  sysctl -w net.ipv4.conf.all.rp_filter=2
  sysctl -w net.ipv4.conf.eth0.rp_filter=2
  sysctl -w net.ipv4.conf.wg0.rp_filter=2
  sysctl -w net.ipv4.ip_forward=1

  wg-quick up wg0

  if ! ip link show wg0 >/dev/null 2>&1; then
    echo "!! CRITICAL: wg0 interface failed to start."
    exit 1
  fi
  echo "--> WireGuard Interface Up."

  echo "nameserver 1.1.1.1" >/etc/resolv.conf
  echo "nameserver 1.0.0.1" >>/etc/resolv.conf
  echo "--> DNS forced to Cloudflare (1.1.1.1)"

  iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

  # FIREWALL / KILL SWITCH
  iptables -F
  iptables -P INPUT DROP
  iptables -P OUTPUT DROP
  iptables -P FORWARD DROP
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

  # Allow Loopback
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT

  # Allow Docker Network / LAN (So you can access WebUI)
  iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
  iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT
  iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT
  iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT
  iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
  iptables -A OUTPUT -d 192.168.0.0/16 -j ACCEPT

  # Allow WireGuard UDP traffic out on eth0 (to connect to VPN server)
  iptables -A OUTPUT -o eth0 -p udp -j ACCEPT
  iptables -A OUTPUT -o wg0 -p udp --dport 53 -j ACCEPT

  # Explicitly allow WebUI port on eth0
  iptables -A INPUT -i eth0 -p tcp --dport 8080 -j ACCEPT
  iptables -A OUTPUT -o eth0 -p tcp --sport 8080 -j ACCEPT

  # Allow All Traffic inside the Tunnel (wg0)
  iptables -A INPUT -i wg0 -j ACCEPT
  iptables -A OUTPUT -o wg0 -j ACCEPT
  if [ ! -z "$VPN_PORT" ]; then
    iptables -A INPUT -i wg0 -p tcp --dport "$VPN_PORT" -j ACCEPT
    iptables -A INPUT -i wg0 -p udp --dport "$VPN_PORT" -j ACCEPT
  fi

  ip link set dev wg0 mtu 1420

  echo "--> Firewall/Killswitch Enabled."
else
  echo "!! No /config/wg0.conf found. Terminating container !!"
  exit 1
fi

echo "--> Running Configuration Script..."
python3 /scripts/configure.py

# TODO: NAT-PMP port forwarding (Proton)

echo "--> Starting qBittorrent..."
exec /usr/bin/qbittorrent-nox --profile=/config
