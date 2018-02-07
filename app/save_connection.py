"""
Save Settings that don't get saved
"""
import NetworkManager

for conn in NetworkManager.NetworkManager.ActiveConnections:
    settings = conn.Connection.GetSettings()
    if conn.Devices:
        devices = [x.Interface for x in conn.Devices]
        if 'wlan1' in devices or 'wlan0' in devices:
            print("Saving connection info for {}".format(settings['connection']['id']))
            NetworkManager.Settings.AddConnection(conn)