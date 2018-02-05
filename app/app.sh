#!/bin/bash

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/host/run/dbus/system_bus_socket

sleep 5

ifconfig wlan0 down

sleep 2

ifconfig wlan0 up

sleep 5

python ./hotspot.py wlan0 up