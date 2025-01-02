#!/bin/bash
# Usage
# ./setup_database.sh dbname dbuser dbpassword domain

# Check if arguments are provided
if [ $# -ne 4 ]; then
    echo "Usage: $0 dbname dbuser dbpassword domain"
    exit 1
fi

DB_NAME=$1
DB_USER=$2
DB_PASS=$3
DOMAIN=$4
LARAVEL_PATH="/var/www/$DOMAIN"

# Update package list
sudo apt update

# Check if MySQL or MariaDB is already installed
if mysql --version | grep -q 'Ver 8'; then
    echo "MySQL is already installed."
else
    echo "Installing MySQL Server 8.0..."
    sudo apt install -y mysql-server-8.0 -y
fi

# Secure MySQL Installation
sudo mysql_secure_installation <<EOF
n
Y
Y
Y
Y
Y
EOF

# Create Database and User
sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

# Update Laravel .env file
ENV_FILE="$LARAVEL_PATH/.env"
if [ -f "$ENV_FILE" ]; then
  sudo sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" $ENV_FILE
  sudo sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" $ENV_FILE
  sudo sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" $ENV_FILE
else
  echo "Laravel .env file not found in $LARAVEL_PATH"
  exit 1
fi

# Output success message
echo "Database setup complete."
echo "Database Name: $DB_NAME"
echo "Username: $DB_USER"
echo "Password: $DB_PASS"
