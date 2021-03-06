#!/bin/bash
# shellcheck shell=bash 
LOGFILE=/tmp/resin.log
exec > >(tee -a $LOGFILE)
exec 2>&1

export PP_SSID=${PP_SSID:-unconfigured-printer-proxy}
export PRINTER_IP=${PRINTER_IP:-10.42.0.10}
export ZEROTIER_NETWORK=${ZEROTIER_NETWORK:-UNSET}
#Enable ip forwarding to route traffic between wifi devices
sysctl -w net.ipv4.ip_forward=1

cp /usr/src/app/dnsmasq.conf /etc/dnsmasq.conf
cp /usr/src/app/wlan1 /etc/network/interfaces.d/wlan1

envsubst < /usr/src/app/hostapd.template > /etc/hostapd/hostapd.conf

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

nmcli dev set wlan1 managed no

# Choose a condition for running WiFi Connect according to your use case:

# 1. Is there a default gateway?
# ip route | grep default

# 2. Is there Internet connectivity?
# nmcli -t g | grep full

if [ -f "/data/firstboot" ]; then
  n=0
  until [ $n -ge 20 ]
  do
    echo "Trying to ping google....."
    ping -c1 www.google.com &>/dev/null && break  # substitute your command here
    n=$[$n+1]
    ifconfig
    sleep 15
  done
fi

# 3. Is there Internet connectivity via a google ping?
wget --spider http://google.com 2>&1

# 4. Is there an active WiFi connection?
#iwgetid -r

if [ $? -eq 0 ]; then
    printf 'Skipping WiFi Connect\n'
else
    printf 'Starting WiFi Connect\n'
    ./wifi-connect -s pp-wifi-setup -p 6rsprinter -i wlan0
    sleep 5
fi

envsubst < /etc/nginx/nginx-template.conf > /etc/nginx/nginx.conf 
envsubst < /etc/nginx/printer-template > /etc/nginx/sites-available/printer

ln -sf /etc/nginx/sites-available/printer /etc/nginx/sites-enabled/printer
 
if [[ ! -L "/var/lib/zerotier-one" && -d "/var/lib/zerotier-one" ]]; then
  echo "Linking ZeroTier to data directory"
  service zerotier-one stop
  if [[ -d "/data/zerotier-one" ]]; then
    rm -rf /var/lib/zerotier-one
  else 
    mv /var/lib/zerotier-one /data/zerotier-one 
  fi
  ln -sf /data/zerotier-one /var/lib/zerotier-one
  chown zerotier-one:zerotier-one /var/lib/zerotier-one
  echo "Starting Zerotier Service"
  service zerotier-one start
  sleep 5
fi

echo "Starting telegraf"
envsubst < /etc/telegraf/telegraf-template.conf > /etc/telegraf/telegraf.conf
systemctl restart telegraf.service

echo "ZeroTier Started with status:"
zerotier-cli info

zerotier-cli listnetworks | grep -q "${ZEROTIER_NETWORK}"

if [ $? -eq 0 ]; then
  echo "Zerotier Network Prsent: ${ZEROTIER_NETWORK}"
elif [ "$ZEROTIER_NETWORK" != "UNSET" ]; then
  zerotier-cli join ${ZEROTIER_NETWORK}
  echo "Zerotier Network Added: ${ZEROTIER_NETWORK}"
fi

touch /data/firstboot


iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE 
iptables -A FORWARD -i wlan0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT 
iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT

ifup wlan1

sleep 5

echo "Starting printer proxy network: ${PP_SSID}"
#python ./hotspot.py wlan0 up
hostapd /etc/hostapd/hostapd.conf &

sleep 1

echo "Starting dns server"
dnsmasq --keep-in-foreground --log-facility=- &

echo "Waiting for printer to be reachable...."
until ping -c1 ${PRINTER_IP} &>/dev/null; do :; done

echo "Found printer starting proxy...."
nginx -g 'daemon off;' &

echo "Running forever ping..."
ping -i 1 ${PRINTER_IP} &>/dev/null 

