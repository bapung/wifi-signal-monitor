#/bin/bash -x

#Retrieve current dir
WD=$(pwd)

#WiFi config location
CONFIG_YAML="/etc/wifimon/config.yaml"

#WIFI PARAM
DEFAULT_SSID= $(cat $CONFIG_YAML | grep SSID | awk '{for (i=2;i<=NF;++i)printf $i}')
DEFAULT_PSK=""
DEFAULT_PASSPHRASE=$(cat $CONFIG_YAML | grep Passphrase | awk '{for (i=2;i<=NF;++i)printf $i}')
WPA_SUPPLICANT_FILE="/etc/wpa_supplicant/wpa_supplicant.conf"

#Setup WiFi
if [ ! -f /etc/network/interfaces.d/wlan0 ]; then
cat << EOT > /etc/network/interfaces.d/wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
iface default inet dhcp
EOT
fi

#Create wpa_supplicant configuration file
#if it is not exist or SSID and PASSPHRASE are mismatch

if [ ! -f $WPA_SUPPLICANT_FILE ] || [ -z $(cat $WPA_SUPPLICANT_FILE | grep -E '$DEFAULT_SSID.*$DEFAULT_PASSPHRASE') ]; then
    wpa_passphrase "$DEFAULT_SSID" "$DEFAULT_PASSPHRASE" > $WPA_SUPPLICANT_FILE
fi


#ENABLE SSH
touch /boot/ssh

# Generate Unique Number
# Use proc data to get serial number, ip to get mac address
# and blkid to get UUID and hash three of them using sha256

UNIQUE_ID=$(echo $(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2) \
     $(ip a | grep "ether" | awk -F " " '{print $2, $8}' | head -n 1 | sed 's/://g') \
     $(blkid | grep -oP 'UUID="\K[^"]+' | sha256sum | awk '{print $1}') | sha256sum |
     awk '{print $1}')

echo $UNIQUE_ID

#Modify Configuration File
if [ -f $CONFIG_YAML ] && [ -z $(cat $CONFIG_YAML | grep $UNIQUE_ID) ]; then
	sed -re 's/(uniqueID: ")[^=]/\1'"$UNIQUE_ID"'\"/' -i $CONFIG_YAML
fi
