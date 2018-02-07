"""
Save Settings that don't get saved
"""
import NetworkManager, uuid

for conn in NetworkManager.NetworkManager.ActiveConnections:
    settings = conn.Connection.GetSettings()
    if settings['connection']['uuid'] != '2b0d0f1d-b79d-43af-bde1-71744625642e' and conn.Devices:
        devices = [x.Interface for x in conn.Devices]
        if 'wlan1' in devices or 'wlan0' in devices:
            print("Saving connection for {}".format(settings['connection']['id']))
            settings['connection']['uuid'] = str(uuid.uuid4())
            NetworkManager.Settings.AddConnection(settings)