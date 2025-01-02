#!/bin/bash
# Usage
# ./setup_nginx_laravel.sh yourdomain.com
# This script sets up Nginx for a Laravel project.

# Check if domain argument is provided
if [ $# -eq 0 ]; then
    echo "Please provide a domain name as an argument."
    exit 1
fi

DOMAIN=$1

# Update and upgrade packages
sudo apt update && sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y

sudo apt install php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip composer -y
sudo apt install php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip -y

# Configure Nginx
sudo tee /etc/nginx/sites-available/$DOMAIN > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/$DOMAIN/public;
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Enable the site (with error handling for existing symlink)
if [ ! -L /etc/nginx/sites-enabled/$DOMAIN ]; then
    sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
else
    echo "Symlink for $DOMAIN already exists in sites-enabled."
fi

# Test Nginx configuration
echo "Testing Nginx configuration..."
if sudo nginx -t; then
    echo "Nginx configuration test passed."
    
    # Reload Nginx
    echo "Reloading Nginx..."
    if sudo systemctl reload nginx; then
        echo "Nginx reloaded successfully."
    else
        echo "Failed to reload Nginx. Please check the Nginx status and logs."
        exit 1
    fi
else
    echo "Nginx configuration test failed. Please check your Nginx configuration."
    echo "The new configuration file is located at /etc/nginx/sites-available/$DOMAIN"
    echo "You may need to modify it manually."
    exit 1
fi

echo "Nginx setup complete for $DOMAIN"
echo "Please ensure your Laravel project is deployed to /var/www/$DOMAIN"
echo "Don't forget to set up your .env file and run necessary Laravel commands."