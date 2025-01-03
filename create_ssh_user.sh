#!/bin/bash
# ./create_ssh_user.sh username

if [ $# -eq 0 ]; then
  echo "Please provide a username as an argument."
  exit 1
fi

USERNAME=$1
sudo adduser --disabled-password --gecos "" $USERNAME

sudo mkdir -p /home/$USERNAME/.ssh
sudo chmod 700 /home/$USERNAME/.ssh

sudo touch /home/$USERNAME/.ssh/authorized_keys
sudo chmod 600 /home/$USERNAME/.ssh/authorized_keys

sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

echo "User $USERNAME created successfully."
echo "Public key can be added to /home/$USERNAME/.ssh/authorized_keys"

sudo usermod -aG sudo $USERNAME

read -p "Enable passwordless sudo for $USERNAME? (y/n): " PASSWORDLESS_SUDO
if [ $PASSWORDLESS_SUDO = "y" ]; then
  echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USERNAME
  echo "Passwordless sudo enabled for $USERNAME."
fi