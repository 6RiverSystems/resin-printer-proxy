"""
Activate a connection by name
"""
import dbus
import NetworkManager
import sys

# Find the connection
# name = sys.argv[1]
connections = NetworkManager.Settings.ListConnections()
connections = dict([(x.GetSettings()['connection']['id'], x) for x in connections])
conn = connections['resin-hotspot']
print(conn)
# Find a suitable device
ctype = conn.GetSettings()['connection']['type']

# else:
dtype = {
    '802-11-wireless': NetworkManager.NM_DEVICE_TYPE_WIFI,
    '802-3-ethernet': NetworkManager.NM_DEVICE_TYPE_ETHERNET,
    'gsm': NetworkManager.NM_DEVICE_TYPE_MODEM,
}.get(ctype,ctype)
print(dtype)

devices = NetworkManager.NetworkManager.GetDevices()

for dev in devices:
    if dev.DeviceType == dtype and dev.State == NetworkManager.NM_DEVICE_STATE_DISCONNECTED:
        print("WIFI DeviceType: {} State: {}".format(dev.DeviceType,dev.State))
        print(dev)
        break
    # else:
    #     print("No suitable and available %s device found" % ctype)
    #     sys.exit(1)
# 
# # And connect
print(dev)
# NetworkManager.NetworkManager.ActivateConnection(conn, dev, "/")