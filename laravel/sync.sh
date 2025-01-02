#!/bin/bash
# Usage
# ./sync.sh local_path user@server:/remote_path

# Check if arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 local_path user@server:/remote_path"
    exit 1
fi

LOCAL_PATH=$1
REMOTE_PATH=$2

# Check for changes in package.json locally
cd $LOCAL_PATH
if git diff --quiet HEAD package.json; then
    echo "No changes detected in package.json."
else
    echo "Changes detected in package.json. Running yarn install..."
    yarn install
fi
yarn build

# Sync Laravel files to the remote server
rsync -avz --progress --exclude=node_modules --exclude=vendor --exclude=.env --exclude=storage/framework/sessions/ $LOCAL_PATH $REMOTE_PATH

# SSH into the server and set permissions
ssh $(echo $REMOTE_PATH | cut -d: -f1) <<EOF
cd $(echo $REMOTE_PATH | cut -d: -f2)
composer install --no-dev --optimize-autoloader
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
php artisan storage:link
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data .
EOF

echo "Laravel files synced successfully."