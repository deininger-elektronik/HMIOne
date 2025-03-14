# **Image aus aktueller Konfiguration erstellen (nach Updates oder großen Änderungen an der Konfiguration)**

## **Inhaltsverzeichnis**

1.  [Per SSH auf DietPi einloggen](#1-per-ssh-auf-dietpi-einloggen)
2.  [Node-RED-Service stoppen](#2-node-red-service-stoppen)
3.  [USB-Stick anschließen und identifizieren](#3-usb-stick-anschlie%C3%9Fen-und-identifizieren)
4.  [USB-Stick partitionieren](#4-usb-stick-partitionieren)
5.  [Partitionen einbinden (mounten)](#5-partitionen-einbinden-mounten)
6.  [SD-Karten-Backup erstellen](#6-sd-karten-backup-erstellen)
7.  [Backup auf FAT32-Partition kopieren](#7-backup-auf-fat32-partition-kopieren)
8.  [Image auf FAT32 Partition des USB Sticks kopieren](#8-image-auf-fat32-partition-des-usb-sticks-kopieren)
9.  [Abschluss](#9-abschluss)
10. [Image auf Windows speichern und verwenden](#10-image-auf-windows-speichern-und-verwenden)

* * *

## **1\. Per SSH auf DietPi einloggen**

Voraussetzungen:

- Der SSH-Agent läuft und enthält den passenden Private Key.
- Die IP-Adresse des DietPi-Geräts ist **10.5.0.115**.

Verbindung aufbauen:

```bash
ssh dietpi@10.5.0.115
```

Falls eine Sicherheitswarnung erscheint, akzeptieren.

* * *

## **2\. Node-RED-Service stoppen**

Node-RED-Service stoppen, um mehr RAM zur Verfügung zu haben!

```bash
sudo systemctl stop node-red
```

* * *

## **3\. USB-Stick anschließen und identifizieren**

Den USB-Stick einstecken und dann ausführen:

```bash
lsblk
```

Der Stick wird höchstwahrscheinlich als **/dev/sda** angezeigt.  
**Stellen Sie sicher, dass Sie nicht versehentlich die SD-Karte (z. B. /dev/mmcblk0) formatieren!**

* * *

## **4\. USB-Stick partitionieren (Alle Daten gehen verloren!)**

1.  **Partitionstabelle auf GPT setzen**:

```bash
sudo parted /dev/sda mklabel gpt
```

2.  **Eine 5GB große FAT32-Partition erstellen**:

```bash
sudo parted /dev/sda mkpart primary fat32 1MiB 5000MiB
```

3.  **Den restlichen Speicher als ext4-Partition nutzen**:

```bash
sudo parted /dev/sda mkpart primary ext4 5000MiB 100%
```

4.  **Partitionierung überprüfen**:

```bash
sudo parted /dev/sda print
```

5.  **Partitionen formatieren**:

```bash
sudo mkfs.vfat -F 32 /dev/sda1
sudo mkfs.ext4 /dev/sda2
```

(Optional: Labels setzen)

```bash
sudo fatlabel /dev/sda1 USB_SHARED
sudo e2label /dev/sda2 LINUX_STORAGE
```

* * *

## **5\. Partitionen einbinden (mounten)**

1.  **Mountpunkte erstellen**:

```bash
sudo mkdir -p /mnt/usb_fat
sudo mkdir -p /mnt/usb_ext4
```

2.  **FAT32-Partition mounten**:

```bash
sudo mount /dev/sda1 /mnt/usb_fat
```

3.  **ext4-Partition mounten**:

```bash
sudo mount /dev/sda2 /mnt/usb_ext4
```

4.  **Partitionen überprüfen**:

```bash
lsblk
```

* * *

## **6\. SD-Karten-Backup erstellen**

1.  **Gerät identifizieren**:

```bash
lsblk
```

Die SD-Karte ist wahrscheinlich **/dev/mmcblk0** mit folgenden Partitionen:

- **/dev/mmcblk0p1** → Boot-Partition (FAT32)
- **/dev/mmcblk0p2** → Root-Partition (ext4)

2.  **Komplett-Backup als Image-Datei erstellen**:

```bash
sudo dd if=/dev/mmcblk0 of=/mnt/usb_ext4/DTSJ3.img bs=4M status=progress
```

3.  **PiShrink herunterladen und installieren**:

```bash
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
sudo mv pishrink.sh /usr/local/bin
```

4.  **Image mit PiShrink verkleinern**:

```bash
cd /mnt/usb_ext4 && sudo pishrink.sh -v -n DTSJ3.img
```

5.  **Falls PiShrink fehlschlägt: Benötigte Tools aktualisieren oder installieren**  
    (nicht direkt neu installieren, sondern nur falls PiShrink nicht funktioniert):  
    Falls der PiShrink-Prozess fehlschlägt, können die Tools manuell aktualisiert werden.  
    Sie sollten bereits als Teil von DietPi installiert sein,  
    aktualisieren der Tools für möglicherweise zu Inkompatibilität mit der DietPi Version.

```bash
sudo apt update && sudo apt install -y wget parted udev e2fsprogs
```

* * *

## **7\. Backup auf FAT32-Partition kopieren**

1.  **Größe prüfen**:

```bash
ls -lh /mnt/usb_ext4/DTSJ3.img
```

Falls die Datei **kleiner als 4GB** ist:

### **[Weiter zu Punkt 8!](#8-image-auf-fat32-partition-des-usb-sticks-kopieren)**

2.b. **Falts das Image größer ist als 4GB:**

Installation von xz-utils:

```sh
sudo apt update
sudo apt install xz-utils
```

Teste, ob `xz` erfolgreich installiert wurde:

```sh
xz --version
```

Falls eine Versionsnummer angezeigt wird, war die Installation erfolgreich.

**Image komprimieren:**

```bash
sudo xz -1 --threads=3 --check=crc32 --verbose /mnt/usb_ext4/DTSJ3.img
```

**Größe erneut prüfen**:

```bash
ls -lh /mnt/usb_ext4/DTSJ3.img.xz
```

Falls die Datei immer noch **größer als 4GB** ist:

**Image komprimieren mit höherer Kompression:**

```bash
sudo xz -2 --threads=3 --check=crc32 --verbose /mnt/usb_ext4/DTSJ3.img
```

## **8\. Image auf FAT32 Partition des USB Sticks kopieren**

Falls die Datei nun **kleiner als 4GB** ist:

3.  **Image auf FAT32 Partition des USB Sticks kopieren**:  
    Die FAT32 Partition ist auch für Windows lesbar!

```bash
sudo cp /mnt/usb_ext4/DTSJ3.img /mnt/usb_fat/
```

* * *

## **9\. Abschluss**

Prüfen, ob die Dateien korrekt gespeichert wurden:

```bash
ls -lh /mnt/usb_fat/ /mnt/usb_ext4/
```

* * *

## **10\. Image auf Windows speichern und verwenden**

1.  **USB-Stick unter DietPi unmounten:**

```bash
umount /dev/sdX1
```

2.  **USB-Stick an einen Windows-PC anschließen.**
3.  **Fehlermeldung zur EXT4-Partition ignorieren.**
4.  **Auf die FAT32-Partition zugreifen.**
5.  **Daten von der FAT32-Partition sichern.**
6.  **Daten für zukünftige Installationen vorbereiten.**
7.  **Bereitstellung für neue Instanzen.**