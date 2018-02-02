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
print("Dtype: {} ctype: {}".format(dtype,ctype))

devices = NetworkManager.NetworkManager.GetDevices()

for dev in devices:
    if dev.DeviceType == dtype:
        print("WIFI DeviceType: {} State: {}".format(dev.DeviceType,dev.State))
        print("Activate device {} and connection {}".format(dev,conn))
        break

# 
# # And connect
#print(dev)
#NetworkManager.NetworkManager.ActivateConnection(conn, dev, "/")