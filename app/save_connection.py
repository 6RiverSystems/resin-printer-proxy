"""
Save Settings that don't get saved
"""
import NetworkManager, uuid, pprint
pp = pprint.PrettyPrinter(indent=4)

for conn in NetworkManager.NetworkManager.ActiveConnections:
    settings = conn.Connection.GetSettings()
    if settings['connection']['uuid'] != '2b0d0f1d-b79d-43af-bde1-71744625642e' and conn.Devices:
        devices = [x.Interface for x in conn.Devices]
        if 'wlan1' in devices or 'wlan0' in devices:
            print("Saving connection for {}".format(settings['connection']['id']))
            settings['connection']['id'] = 'resin-wifi-01'
            conn.Connection.Update(settings)
            pp.pprint(settings)
            #NetworkManager.Settings.AddConnection(settings)