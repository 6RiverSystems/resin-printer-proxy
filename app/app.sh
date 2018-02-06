#!/bin/bash
# shellcheck shell=dash 

: ${PRINTER_IP?"Need to set PRINTER_IP"}
: ${ZEROTIER_NETWORK?"Need to set ZEROTIER_NETWORK"}

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
    ./wifi-connect -s pp-wifi-setup -p 6rsprinter -i wlan0
fi

envsubst < /etc/nginx/nginx-template.conf > /etc/nginx/nginx.conf 
envsubst < /etc/nginx/printer-template > /etc/nginx/sites-available/printer

ln -sf /etc/nginx/sites-available/printer /etc/nginx/sites-enabled/printer

ifconfig

sleep 5

ifconfig wlan0 down
ifconfig wlan1 down

sleep 2
ifconfig wlan1 up

sleep 2
ifconfig wlan0 up

sleep 5

python ./hotspot.py wlan0 up

service zerotier-one stop 

mkdir -p /data/zerotier-one 

ln -sf /data/zerotier-one /var/lib/zerotier-one

service zerotier-one start

nginx -g 'daemon off;'