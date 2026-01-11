import os
import configparser

CONF_PATH = '/config/qBittorrent/config/qBittorrent.conf'
# Note: qBittorrent 4.2+ stores config in /config/qBittorrent/config/qBittorrent.conf 

def load_config():
    config = configparser.ConfigParser()
    config.optionxform = str
    config.read(CONF_PATH)
    return config

def save_config(config):
    os.makedirs(os.path.dirname(CONF_PATH), exist_ok=True)
    with open(CONF_PATH, 'w') as configfile:
        config.write(configfile)

def apply_vars(config):
    if 'Preferences' not in config: config['Preferences'] = {}
    if 'Network' not in config: config['Network'] = {}
    
    prefs = config['Preferences']

    if os.getenv('VPN_ENABLED') == 'true':
        prefs[r'Connection\Interface'] = 'wg0'
        prefs[r'Connection\InterfaceName'] = 'wg0'

    if os.getenv('VPN_PORT'):
        port = os.getenv('VPN_PORT')
        prefs[r'Connection\PortRangeMin'] = port
        prefs[r'Connection\PortRangeMaconfx'] = port
        print(f"--> Config: Static Listening Port set to {port}")

    prefs[r'Network\UPnP'] = 'false'
    prefs[r'Network\NATPMP'] = 'false'
    prefs[r'WebUI\LocalHostAuth'] = 'false'
    prefs[r'Connection\InetMode'] = 'IPv4' 
    prefs[r'BitTorrent\AutoTMM'] = 'true'
    prefs[r'WebUI\HostHeaderValidation'] = 'false'
    prefs[r'WebUI\CSRFProtection'] = 'false'
    prefs[r'Advanced\osCache'] = 'false'
    prefs[r'Advanced\AsyncIOThreads'] = '16'
    prefs[r'Session\DiskIOType'] = '1' 
    prefs[r'Advanced\CalculationSize'] = '256'
    prefs[r'Advanced\AnnounceToAllTrackers'] = 'true'
    prefs[r'Advanced\AnnounceToAllTiers'] = 'true'
    prefs[r'Advanced\ValidateHTTPS'] = 'false' # Helps with some tracker issues

    # Your Opinionated Customisations

    print(f"Applied settings. Interface bound to: {prefs.get(r'Connection\Interface', 'default')}")

if __name__ == "__main__":
    cfg = load_config()
    apply_vars(cfg)
    save_config(cfg)
