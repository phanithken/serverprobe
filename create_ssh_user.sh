#!/bin/bash
# ./create_ssh_user.sh username domain

if [ $# -ne 2 ]; then
  echo "Usage ./create_ssh_user.sh username"
  exit 1
fi

USERNAME=$1
DOMAIN=$2

if id "$USERNAME" &>/dev/null; then
  echo "User $USERNAME already exists. Skipping user creation."
  exit 1
else
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
fi

if ! command -v lsyncd &> /dev/null; then
  echo "Installing lsyncd..."
  sudo apt update && sudo apt install lsyncd -y
fi

LSYNCD_CONF="/etc/lsyncd/lsyncd_$USERNAME.conf"
sudo tee $LSYNCD_CONF > /dev/null <<EOF
settings {
  logfile = "/var/log/lsyncd/lsyncd_$USERNAME.log",
  statusFile = "/var/log/lsyncd/lsyncd_$USERNAME.status",
}
sync {
  default.rsync,
  source = "/home/$USERNAME/$DOMAIN",
  target = "/var/www/$DOMAIN",
  rsync = {
    archive = true,
    compress = true,
    whole_file = false,
  }
}
EOF

sudo systemctl enable lsyncd
sudo systemctl restart lsyncd

echo "lsyncd configuration created for $USERNAME."