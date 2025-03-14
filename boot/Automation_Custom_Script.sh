#!/bin/bash
# Infineon Optiga™ SLB 9670 TPM 2.0 Setup Script for DietPi on Raspberry Pi 4

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
sudo modprobe tpm_tis_spi

# Ensure the TPM driver loads at boot
if ! sudo grep -q "tpm_tis_spi" /etc/modules; then
    echo "tpm_tis_spi" | sudo tee -a /etc/modules > /dev/null
fi

# Step 4: Enable and start the TPM daemon
sudo systemctl enable tpm2-abrmd

# Step 5: Set environment variable for TPM tools (persistent)
echo 'export TPM2TOOLS_TCTI="device:/dev/tpm0"' >> ~/.bashrc
sudo export TPM2TOOLS_TCTI="device:/dev/tpm0"

# ----- Not Tested yet!!!

#--------- No Cursor
#Edit /etc/X11/xinit/xserverrc:
sudo nano /etc/X11/xinit/xserverrc

echo 'exec /usr/bin/Xorg -nocursor "$@"' | sudo tee /etc/X11/xinit/xserverrc > /dev/null


sudo chown kioskuser:kioskuser /home/kioskuser/.xserverrc
sudo chmod +x /home/kioskuser/.xserverrc


#------------ Certs 
#Add to chromium CA store
sudo cp /boot/PostBootScripts/rootCA.pem /usr/local/share/ca-certificates/rootCA.crt
sudo update-ca-certificates

sudo -u kioskuser cp /boot/PostBootScripts/nssdb /home/kioskuser/.pki/nssdb


# copy TPM SETUP script to secure location!!


sudo mkdir -p /opt/tpm-tools
sudo cp /boot/PostBootScripts/tpm_config.py /opt/tpm-tools/
sudo chown dietpi:dietpi /opt/tpm-tools/tpm_config.py
sudo chmod 700 /opt/tpm-tools/tpm_config.py

echo "TPM configuration script installed successfully."


# add users to dialout group for RS-485

sudo usermod -a -G dialout nodered

# maybe not add dietpi to dialout fore security not sure
sudo usermod -a -G dialout dietpi

exit 0
