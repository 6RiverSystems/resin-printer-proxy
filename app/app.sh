#!/bin/bash
# shellcheck shell=bash 

: ${PRINTER_IP?"Need to set PRINTER_IP"}
: ${ZEROTIER_NETWORK?"Need to set ZEROTIER_NETWORK"}


sysctl -w net.ipv4.ip_forward=1

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

# Choose a condition for running WiFi Connect according to your use case:

# 1. Is there a default gateway?
# ip route | grep default

# 2. Is there Internet connectivity?
# nmcli -t g | grep full

# 3. Is there Internet connectivity via a google ping?
wget --spider http://google.com 2>&1

# 4. Is there an active WiFi connection?
#iwgetid -r

if [ $? -eq 0 ]; then
    printf 'Skipping WiFi Connect\n'
else
    printf 'Starting WiFi Connect\n'
    ./wifi-connect -s pp-wifi-setup -p 6rsprinter
fi

envsubst < /etc/nginx/nginx-template.conf > /etc/nginx/nginx.conf 
envsubst < /etc/nginx/printer-template > /etc/nginx/sites-available/printer

ln -sf /etc/nginx/sites-available/printer /etc/nginx/sites-enabled/printer

ifconfig

# sleep 5
# 
# ifconfig wlan0 down
# ifconfig wlan1 down
# 
# sleep 2
# ifconfig wlan1 up
# 
# sleep 2
# ifconfig wlan0 up
# 
# sleep 5
# 

python ./hotspot.py wlan1 up

 
if [[ ! -L "/var/lib/zerotier-one" && -d "/var/lib/zerotier-one" ]]; then
  echo "Linking ZeroTier to data directory"
  service zerotier-one stop
  mv /var/lib/zerotier-one /data/zerotier-one 
  ln -sf /data/zerotier-one /var/lib/zerotier-one
  chown zerotier-one:zerotier-one /var/lib/zerotier-one
  echo "Starting Zerotier Service"
  service zerotier-one start
  sleep 5
fi


echo "ZeroTier Started with status:"
zerotier-cli info

zerotier-cli listnetworks | grep -q "${ZEROTIER_NETWORK}"

if [ $? -eq 0 ]; then
  echo "Zerotier Network Prsent: ${ZEROTIER_NETWORK}"
else 
  zerotier-cli join ${ZEROTIER_NETWORK}
  echo "Zerotier Network Added: ${ZEROTIER_NETWORK}"
fi

iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE  
iptables -A FORWARD -i wlan0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT  
iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT

echo "Waiting for printer to be reachable...."
until ping -c1 www.google.com &>/dev/null; do :; done

nginx -g 'daemon off;'