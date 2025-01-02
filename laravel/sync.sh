#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 local_path server domain"
    exit 1
fi

LOCAL_PATH=$1

# server is the host in ~/.ssh/config
SERVER=$2
REMOTE_PATH="/var/www/$3"

cd $LOCAL_PATH
if git diff --quiet HEAD package.json; then
    echo "No changes detected in package.json."
else
    echo "Changes detected in package.json. Running yarn install..."
    yarn install
fi
yarn build

rsync -avz --delete --exclude-from="$LOCAL_PATH/.gitignore" --exclude='.git' --include='public/build' \
    -e "ssh -o PubkeyAuthentication=no" "$LOCAL_PATH/" "$SERVER:$REMOTE_PATH"

ssh -o PubkeyAuthentication=no $SERVER <<EOF
mkdir -p $REMOTE_PATH
cd $REMOTE_PATH
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