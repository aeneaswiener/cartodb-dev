#!/usr/bin/env bash

cd /usr/local/src/cartodb
bundle install

# Configure CartoDB
mv config/app_config.yml.sample config/app_config.yml
mv config/database.yml.sample config/database.yml

# get postgres to drop all security
mv /etc/postgresql/9.1/main/pg_hba.conf /etc/postgresql/9.1/main/pg_hba.conf.original
ln -s /usr/local/src/cartodb-dev/config/pg_hba.conf /etc/postgresql/9.1/main/pg_hba.conf

/etc/init.d/postgresql restart

sleep 5s

export USER=production
export PASSWORD=production
export ADMIN_PASSWORD=production
export EMAIL=production@production.com

echo "127.0.0.1 ${USER}.localhost.lan" | sudo tee -a /etc/hosts

# Start redis for setup, will be shut down at the end of setup
sudo redis-server&

# Set up databases and development user
bundle exec rake rake:db:create:all
bundle exec rake rake:db:migrate
bundle exec rake cartodb:db:create_publicuser
bundle exec rake cartodb:db:create_user SUBDOMAIN="${USER}" PASSWORD="${PASSWORD}" EMAIL="${EMAIL}"
bundle exec rake cartodb:db:create_importer_schema
bundle exec rake cartodb:db:load_functions

# Create production user
RAILS_ENV=production sudo -E bundle exec rake rake:db:migrate
RAILS_ENV=production sudo -E bundle exec rake cartodb:db:create_user SUBDOMAIN="${USER}" PASSWORD="${PASSWORD}" EMAIL="${EMAIL}"
RAILS_ENV=production sudo -E bundle exec rake cartodb:db:load_functions

# Restore redis 
RAILS_ENV=production sudo -E script/restore_redis

# Precompile assets
RAILS_ENV=production sudo -E bundle exec rake assets:precompile

# Start server using
# RAILS_ENV=production sudo -E bundle exec foreman start -p 3000

# ln -s /usr/local/etc/cartodb.development.js /usr/local/src/CartoDB-SQL-API/config/environments/development.js
# ln -s /usr/local/etc/windshaft.development.js /usr/local/src/Windshaft-cartodb/config/environments/development.js

redis-cli shutdown

# /etc/init.d/redis-server stop
