#!/bin/bash

LIST_OF_APPS="ubuntu-restricted-extras synaptic gnome-shell-extensions chrome-gnome-shell playonlinux curl gparted neovim mysql-workbench vim gedit p7zip-full p7zip-rar shutter libfreerdp-plugins-standard chromium-browser libnss3-tools vlc firefox libpng-dev net-tools apt-transport-https ca-certificates software-properties-common"

# Update app repository, upgrade installed application
sudo apt update && sudo apt upgrade -y

# ttf-mscorefonts-installer
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
sudo apt install ttf-mscorefonts-installer -y




# Java
sudo apt update && sudo apt upgrade -y
sudo apt install default-jre default-jdk -y



# Install list of apps
sudo apt install $LIST_OF_APPS -y

# Docker
sudo apt install docker.io -y
sudo systemctl enable --now docker
sudo usermod -aG docker $USER
 


# VSCode
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install code -y
echo 'fs.inotify.max_user_watches=524288' | sudo tee -a /etc/sysctl.conf > /dev/null

# Postman
wget https://dl.pstmn.io/download/latest/linux64 -O postman.tar.gz
sudo tar -xzf postman.tar.gz -C /opt
rm postman.tar.gz
sudo ln -s /opt/Postman/Postman /usr/bin/postman

# Fix - Visual Studio Code is unable to watch for file changes in this large workspace
echo 'fs.inotify.max_user_watches=524288' | sudo tee -a /etc/sysctl.conf > /dev/null

# Update Distribution packages
sudo apt update && sudo apt dist-upgrade -y

# Skype
sudo snap install skype --classic

# Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb


# Enable firewall
sudo ufw enable

# Clean packages
sudo apt auto-remove -y