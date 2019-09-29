cd `dirname "${BASH_SOURCE[0]}"`
sudo mkdir -p "/Library/Application Support/HyperOrchid/"
sudo cp sysproxyconfig "/Library/Application Support/HyperOrchid/"
sudo chown root:admin "/Library/Application Support/HyperOrchid/sysproxyconfig"
sudo chmod +s "/Library/Application Support/HyperOrchid/sysproxyconfig"

echo done
