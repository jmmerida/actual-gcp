#!/bin/bash

git clone https://github.com/jmmerida/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
apt-get update && apt-get install -y wget
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
apt-get update && apt-get install -y gnupg software-properties-common
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt-get install terraform