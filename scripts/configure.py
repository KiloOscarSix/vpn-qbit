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
    prefs = config['Preferences']

    # Bind to WireGuard Interface
    if os.getenv('VPN_ENABLED') == 'true':
        prefs['Connection\Interface'] = 'wg0'
        prefs['Connection\InterfaceName'] = 'wg0'

    # Your Opinionated Customisations

    print(f"Applied settings. Interface bound to: {prefs.get('Connection\Interface', 'default')}")

if __name__ == "__main__":
    cfg = load_config()
    apply_vars(cfg)
    save_config(cfg)
