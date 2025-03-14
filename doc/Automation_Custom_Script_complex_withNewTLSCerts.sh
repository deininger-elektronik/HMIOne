#!/bin/bash
# Infineon Optiga™ SLB 9670 TPM 2.0 Setup Script for DietPi on Raspberry Pi 4

echo "----------------------------"
echo "Starting TPM 2.0 Setup..."
echo "----------------------------"

# Step 1: Enable SPI in /boot/config.txt if not already enabled
if ! grep -q "dtparam=spi=on" /boot/config.txt; then
    echo "Enabling SPI..."
    echo "dtparam=spi=on" | tee -a /boot/config.txt
fi

# Done in dietpi.txt via AUTO_SETUP_APT_INSTALLS= tpm2-tools tpm2-abrmd libtss2-tcti-tabrmd0
# Step 2: Install required TPM 2.0 packages
#echo "Installing TPM2 software..."
#sudo apt update
#sudo apt install -y tpm2-tools tpm2-abrmd libtss2-tcti-tabrmd0 libnss3-tools

# Step 3: Load TPM SPI driver
echo "Loading TPM SPI driver..."
sudo modprobe tpm_tis_spi

# Ensure the TPM driver loads at boot
echo "Making TPM SPI driver persistent..."
if ! sudo grep -q "tpm_tis_spi" /etc/modules; then
    echo "tpm_tis_spi" | sudo tee -a /etc/modules > /dev/null
fi

# Step 4: Enable and start the TPM daemon
echo "Enabling TPM2 daemon..."
sudo systemctl enable tpm2-abrmd

# Step 5: Set environment variable for TPM tools (persistent)
echo "Configuring TPM environment..."
echo 'export TPM2TOOLS_TCTI="device:/dev/tpm0"' >> ~/.bashrc
sudo export TPM2TOOLS_TCTI="device:/dev/tpm0"

echo "----------------------------"
echo "TPM 2.0 Setup Complete!"
echo "----------------------------"


# ----- Not Tested yet!!!

#--------- No Cursor
#Edit /etc/X11/xinit/xserverrc:
sudo nano /etc/X11/xinit/xserverrc

echo 'exec /usr/bin/Xorg -nocursor "$@"' | sudo tee /etc/X11/xinit/xserverrc > /dev/null


sudo chown kioskuser:kioskuser /home/kioskuser/.xserverrc
sudo chmod +x /home/kioskuser/.xserverrc

#------------ Certs 
# create tls certs for node red:
sudo mkdir -p /mnt/dietpi_userdata/RCA/
cd /mnt/dietpi_userdata/RCA/

# create ROOT CA

sudo openssl genrsa -out rootCA.key 4096

sudo openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem -subj "/C=DE/ST=BW/L=Weingarten Baden/O=Deininger Elektronik/CN=Deininger CA"

sudo cp rootCA.pem /usr/local/share/ca-certificates/deininger-ca.crt
sudo update-ca-certificates

# Create Cert
# Create the file and write the content into it
sudo tee /etc/ssl/node-red-san.cnf > /dev/null << EOF
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
EOF

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



exit 0
