#!/bin/bash

# locatedt in: /boot/Automation_Custom_PreScript.sh

# Check if user exists, if not, create it
if ! id "kioskuser" &>/dev/null; then
    sudo useradd -m -s /bin/bash kioskuser
    sudo usermod -aG video,render,input,tty kioskuser  # Add permissions for X11/Chromium
fi