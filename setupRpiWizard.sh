#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

NAME=$(basename $0)

# Check if root
if [ $(id -u) -ne 0 ]; then
  printf "\n${RED}Script must be run as root. Try${NC} 'sudo $NAME'\n\n"
  #exit 1
fi

# Check if log exists, if not: Running critical settings
if [ ! -f ./logfig ]; then
    echo "First run initiated" 2> logfig
    sudo raspi-config --expand-rootfs
    echo "Filesystem expanded" 2>> logfig
    sudo raspi-config --configure-keyboard
    echo "Keyboard configured" 2>> logfig
    sudo raspi-config --change_locale
    echo "Locale changed" 2>> logfig
    sudo raspi-config --change_timezone
    echo "Timezone changed" 2>> logfig
    sudo shutdown -r now
fi

### Nano wpa_supplicant.conf
function WIFI() {
    echo "Configurating WiFi"
    echo -e "\n\n${GREEN}Do you want to setup wifi? (y/n) ${NC}\n"
    read wifiInpu
    if [[ "$wifiInpu" == "y" || "$wifiInpu" == "Y" ]]; then
        WPASUPPLICANT="/etc/wpa_supplicant/wpa_supplicant.conf"
        echo -e "\n\n${GREEN}Type the SSID of the network you want to connect to and press [ENTER]:${NC}\n"
        read SSID
        echo -e "\n\n${GREEN}Type the PASSWORD of the network you want to connect to and press [ENTER]:${NC}\n"
        read PASSWORD
        HASHEDSSIDPWPA=`sudo wpa_passphrase $SSID $PASSWORD`
        if [[ "$HASHEDSSIDPWPA" == "Passphrase must be 8..63 characters" ]]; then
            echo -e "\n\n${RED}$HASHEDSSIDPWPA${NC}\n"
            WIFI
        else
            echo "${HASHEDSSIDPWPA}" | grep -v "#psk" >> $WPASUPPLICANT
            sudo chmod 600 $WPASUPPLICANT
            sudo chown root:root $WPASUPPLICANT
            printf "\nConfigurating WiFi done"
        fi
    fi
}

# REMOVE LOCK
function LOCK() {
    sudo rm /var/lib/dpkg/lock
    sudo dpkg --configure -a
}

# UPDATE SYSTEM
function UPDATE() {
    echo "Upgrading system"
    sudo apt-get update -y
    sudo apt-get upgrade -y
    echo "Upgrading system done"
}

# ADD NEW USER AND SET PERMS
function NEWUSER() {
    printf "\n\n${GREEN}Enter the new USERNAME (root) now:${NC}\n"
    read newUSERNAME
    sudo adduser $newUSERNAME
    sudo passwd $newUSERNAME
    sudo usermod $newUSERNAME -a -G pi,adm,dialout,cdrom,sudo,audio,video,plugdev,games,users,input,netdev,spi,i2c,gpio
}

# Check if newUSERNAME is in sudoers
function NEWUSERROOT() {
    IFS=$'\n'
    SUDOERSFILE="/etc/sudoers.d/010_pi-nopasswd"
    PIINSUDOERS=`sudo grep -F "PI" $SUDOERSFILE`
    NEWUSERINSUDOERS=`sudo grep -F "$newUSERNAME" $SUDOERSFILE`
    LINESINSUDOERS=`sudo cat $SUDOERSFILE | wc -l`

    # Check if PI is in sudoers and delete it
    if [ "$PIINSUDOERS" ]; then
        printf "PI IN SUDOERS"
        if [[ "$LINESINSUDOERS" == 1 ]]; then
            printf "SUDOERS IS ONLY ONE LINE"
            sudo rm $SUDOERSFILE
            sudo echo "$newUSERNAME ALL=(ALL) NOPASSWD: ALL" > $SUDOERSFILE
        else
            printf "SUDOERS HAS MORE THAN ONE ENTRY"
            PIINSUDOERSLINE=`sudo awk '/(^| )'$PIINSUDOERS'( |$)/{print NR}' $SUDOERSFILE`
            PIINSUDOERSLINE=`sudo echo $PIINSUDOERSLINE | rev`
            IFS=$' '
            for f in $PIINSUDOERSLINE; do
                echo "$f"
                sudo sed -i -e $f"d" $SUDOERSFILE
            done
            IFS=$'\n'
        fi
    fi

    # Check if the new user is in sudoers
    if [ -z "$NEWUSERINSUDOERS" ]; then
        printf "$NEWUSERINSUDOERS NOT IN SUDOERS"
        sudo echo "$newUSERNAME ALL=(ALL) NOPASSWD: ALL" >> $SUDOERSFILE
    else
        printf "$newUSERNAME IN SUDOERS"
    fi

    sudo chattr +i /etc/sudoers.d/010_pi-nopasswd
    printf "/etc/sudoers.d/010_pi-nopasswd is now unmodifiable"

    sudo chattr +i /home/$newUSERNAME/.bashrc
    printf "/home/$newUSERNAME/.bashrc is now unmodifiable"
}

# SET MOTD
function MOTD() {
    printf "Setting up new MOTD"
    sudo rm /etc/motd
    sudo apt-get install screenfetch -y
    sudo cp /etc/update-motd.d/10-uname /etc/update-motd.d/11-banner
    sudo chown $newUSERNAME /etc/update-motd.d/11-banner
    sudo chmod a+x /etc/update-motd.d/11-banner
    sudo echo '#!/bin/bash
    sudo screenfetch' > /etc/update-motd.d/11-banner
    sudo bash /etc/update-motd.d/11-banner
    printf "Setting new MOTD done"
}

# DELETE PI USER
function DELPI() {
    printf "Deleting PI user"
    sudo userdel pi
    sudo rm -rf /home/pi
    printf "Deleting PI user done"
}

# SET NEW HOSTNAME
function HOSTNAME() {
    CURRENT_HOSTNAME=`cat /etc/hostname | tr -d " \t\n\r"`
    printf "\n\n${GREEN}ENTER NEW HOSTNAME:${NC}\n"
    read NEW_HOSTNAME
    echo $NEW_HOSTNAME > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    printf "New hostname is set"
}

WIFI
LOCK
UPDATE
NEWUSER
NEWUSERROOT
MOTD
DELPI
HOSTNAME

printf "${GREEN}\n\nSETUP ALL DONE - REBOOTING NOW [PRESS ENTER]${NC}\n\n"; read -p " "
sudo shutdown -r now
