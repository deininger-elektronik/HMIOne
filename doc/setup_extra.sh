[ ] Set Read-Only FS in config
[ ]	Disable SWAP
[ ]	Set Node-RED varibales to memory only
[ ]
[ ]

--------------------------
#NO CURSOR

#Edit /etc/X11/xinit/xserverrc:
sudo nano /etc/X11/xinit/xserverrc

#Replace the existing exec Xorg line with:
exec /usr/bin/Xorg -nocursor "$@"
#Save and exit (CTRL + X, Y, Enter).
sudo chown kioskuser:kioskuser /home/kioskuser/.xserverrc
sudo chmod +x /home/kioskuser/.xserverrc
-------------------

# create tls certs for node red:
sudo mkdir -p /mnt/dietpi_userdata/RCA/
cd /mnt/dietpi_userdata/RCA/

# create ROOT CA

sudo openssl genrsa -out rootCA.key 4096

sudo openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem -subj "/C=DE/ST=BW/L=Weingarten Baden/O=Deininger Elektronik/CN=Deininger CA"

sudo cp rootCA.pem /usr/local/share/ca-certificates/deininger-ca.crt
sudo update-ca-certificates

# Create Cert
sudo nano node-red-san.cnf


[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
req_extensions     = v3_req
prompt            = no

[ req_distinguished_name ]
C  = DE
ST = BW
L  = Weingarten Baden
O  = Deininger Elektronik
CN = 127.0.0.1

[ v3_req ]
subjectAltName = @alt_names

[ alt_names ]
IP.1 = 127.0.0.1
DNS.1 = localhost



sudo openssl genrsa -out node-red.key 4096
  
openssl req -new -key privkey.pem -out node-red.csr -config node-red-san.cnf

sudo openssl x509 -req -in node-red.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out node-red.crt -days 3650 -sha256 -extfile node-red-san.cnf

sudo mv node-red.crt /mnt/dietpi_userdata/node-red/ssl/cert.pem
sudo mv node-red.key /mnt/dietpi_userdata/node-red/ssl/privkey.pem

sudo chown nodered:nodered /mnt/dietpi_userdata/node-red/ssl/*
sudo chmod 600 /mnt/dietpi_userdata/node-red/ssl/*


sudo systemctl restart node-red



#Add to chromium CA store
sudo cp rootCA.pem /usr/local/share/ca-certificates/rootCA.crt
sudo update-ca-certificates

sudo -u kioskuser mkdir -p /home/kioskuser/.pki/nssdb

sudo apt update
sudo apt install libnss3-tools -y


sudo -u kioskuser certutil -N -d sql:/home/kioskuser/.pki/nssdb --empty-password


sudo cp rootCA.pem /home/kioskuser/rootCA.pem
sudo chown kioskuser:kioskuser /home/kioskuser/rootCA.pem
sudo chmod 644 /home/kioskuser/rootCA.pem


sudo -u kioskuser certutil -A -n "Node-RED Root CA" -t "CT,c,C" -i /home/kioskuser/rootCA.pem -d sql:/home/kioskuser/.pki/nssdb


sudo -u kioskuser certutil -L -d sql:/home/kioskuser/.pki/nssdb






# DOes not work because no Root CA!!   
# sudo nano openssl-san.cnf
# 
# [ req ]
# default_bits       = 4096
# distinguished_name = req_distinguished_name
# x509_extensions    = v3_ca
# prompt            = no
# 
# [ req_distinguished_name ]
# C  = DE
# ST = BW
# L  = Weingarten Baden
# O  = Deininger Elektronik
# CN = DTSJ3
# 
# [ v3_ca ]
# subjectAltName = @alt_names
# 
# [ alt_names ]
# IP.1 = 127.0.0.1
# DNS.1 = localhost
# 
# sudo openssl req -x509 -newkey rsa:4096 -keyout privkey.pem -out cert.pem -days 3650 -nodes -config openssl-san.cnf

#sudo chown nodered:nodered /mnt/dietpi_userdata/node-red/ssl/*
#sudo chmod 600 /mnt/dietpi_userdata/node-red/ssl/*




# Alternativly: but gives error because no SAN (sudo systemctl restart node-red)

# sudo mkdir -p /mnt/dietpi_userdata/node-red/ssl/
# sudo openssl req -x509 -newkey rsa:4096 -keyout /mnt/dietpi_userdata/node-red/ssl/private.key -out /mnt/dietpi_userdata/node-red/ssl/certificate.crt -days 3650 -nodes
# 
# sudo mv /mnt/dietpi_userdata/node-red/ssl/private.key /mnt/dietpi_userdata/node-red/ssl/privkey.pem
# 
# sudo mv /mnt/dietpi_userdata/node-red/ssl/certificate.crt /mnt/dietpi_userdata/node-red/ssl/cert.pem
# 
# 
# sudo chown nodered:nodered /mnt/dietpi_userdata/node-red/ssl/privkey.pem
# sudo chown nodered:nodered /mnt/dietpi_userdata/node-red/ssl/cert.pem
# 
# sudo chmod 600 /mnt/dietpi_userdata/node-red/ssl/privkey.pem
# sudo chmod 644 /mnt/dietpi_userdata/node-red/ssl/cert.pem
# 
# sudo systemctl restart node-red




#Add to trust store for Chromium not to throw a cert error
#sudo cp /mnt/dietpi_userdata/node-red/ssl/cert.pem /usr/local/share/ca-certificates/node-red.crt

#sudo update-ca-certificates




-----------------
dietpi custom auto start script at 

/var/lib/dietpi/dietpi-autostart/custom.sh


# run kiosk mode in sandbox
useradd -m -s /bin/bash kiosk
chown -R kiosk:kiosk /home/kiosk
su - kiosk -c 'chromium --kiosk --disable-restore-session-state --app=http://localhost:1880/ui'


or 

su - kiosk -c "chromium --kiosk --disable-restore-session-state --app=http://localhost:1880/ui"


Modify the dietpi-autostart script:

nano /var/lib/dietpi/dietpi-autostart/custom.sh
Add:
su - kiosk -c "chromium --kiosk --disable-restore-session-state --app=http://localhost:1880/ui"
---
set hostname based on rpi serial nummber from readonly memory 

----

copy flows.json from /boot/node-red-config to replace /mnt/dietpi_userdata/node-red/flows_<hostname>.json while using the right hostname

----
set permissions for flows.json and settings.js

#!/bin/bash

# Stop Node-RED before modifying files
systemctl stop nodered

# Define paths
BOOT_PATH="/boot/node-red-config"
NODE_RED_PATH="/mnt/dietpi_userdata/node-red"
HOSTNAME=$(hostname)
FLOWS_FILE="flows_${HOSTNAME}.json"
SETTINGS_FILE="settings.js"

# Replace the flows file if it exists in /boot
if [ -f "$BOOT_PATH/flows.json" ]; then
    cp "$BOOT_PATH/flows.json" "$NODE_RED_PATH/$FLOWS_FILE"
    chown nodered:nodered "$NODE_RED_PATH/$FLOWS_FILE"
    chmod 644 "$NODE_RED_PATH/$FLOWS_FILE"
fi

# Replace the settings.js file if it exists in /boot
if [ -f "$BOOT_PATH/settings.js" ]; then
    cp "$BOOT_PATH/settings.js" "$NODE_RED_PATH/$SETTINGS_FILE"
    chown nodered:nodered "$NODE_RED_PATH/$SETTINGS_FILE"
    chmod 644 "$NODE_RED_PATH/$SETTINGS_FILE"
fi

# Restart Node-RED to apply changes
systemctl start nodered
