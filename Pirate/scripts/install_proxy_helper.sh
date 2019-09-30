cd `dirname "${BASH_SOURCE[0]}"`

sudo mkdir -p "/Library/Application Support/Pirate/"
sudo cp sysproxyconfig "/Library/Application Support/Pirate/"
sudo chown root:admin "/Library/Application Support/Pirate/sysproxyconfig"
sudo chmod +s "/Library/Application Support/Pirate/sysproxyconfig"

echo done
