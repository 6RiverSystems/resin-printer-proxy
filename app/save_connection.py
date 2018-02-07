"""
Save Settings that don't get saved
"""
import NetworkManager

for conn in NetworkManager.NetworkManager.ActiveConnections:
    settings = conn.Connection.GetSettings()
    print("Looking at connection {}".format(settings['connection']['id']))
    if 'wlan1' in conn.Devices or 'wlan0' in conn.devices:
        print("Saving connection info for {}".format(settings['connection']['id']))
        conn.Connection.Save()