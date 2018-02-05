#!/bin/ash

: ${PRINTER_IP?"Need to set PRINTER_IP"}
export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

envsubst < /etc/nginx/nginx-template.conf > /etc/nginx/nginx.conf 
envsubst < /etc/nginx/printer-template > /etc/nginx/sites-avaliable/printer

ln -s /etc/nginx/sites-avaliable/printer /etc/nginx/sites-enabled/printer

sleep 5

ifconfig wlan0 down

sleep 2

ifconfig wlan0 up

sleep 5

python ./hotspot.py wlan0 up

service zerotier-one stop 

rm -rf /var/lib/zerotier-one/*
mkdir -p /data/zerotier-one 

ln -s /data/zerotier-one /var/lib/zerotier-one

service zerotier-one start

nginx -g 'daemon off;'