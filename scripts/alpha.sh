#!/usr/bin/env bash

echo 'starting provisioning'

# setup apt-get to pull from apt.postgresql.org

echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main 9.5" > /etc/apt/sources.list.d/pgdg.list
wget -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -
#
update apt
apt-get update
apt-get -y -q install pgdg-keyring
#
## install postgresql and a bunch of accessories
apt-get -y -q install postgresql-client-9.5
apt-get -y -q install postgresql-9.5
apt-get -y -q install postgresql-contrib-9.5


sudo -u postgres bash -c "cat > /etc/postgresql/9.5/main/pg_hba.conf <<- _EOF1_
local   all             postgres                                trust

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
# Allow replication connections from localhost, by a user with the
# replication privilege.
#local   replication     postgres                                peer
#host    replication     postgres        127.0.0.1/32            md5
#host    replication     postgres        ::1/128                 md5
host    replication     replication     192.168.4.3/32   md5
_EOF1_
"

sudo service postgresql restart

# Tworze usera DB
psql -U postgres -c "CREATE USER replication REPLICATION LOGIN CONNECTION LIMIT 1 PASSWORD '000000';"

# Lacznosc pomiedzy serwerami przez postgresa
echo -e "postgres\npostgres" | sudo passwd postgres
echo -e "\n\n\n\n" | sudo -u postgres bash -c ssh-keygen
su postgres <<'EOF'
echo -e "yes\npostgres" | ssh-copy-id 192.168.4.3
EOF

# Zmodyfikuj postgresql.conf
sudo -u postgres bash -c "cat >> /etc/postgresql/9.5/main/postgresql.conf <<- _EOF1_
listen_addresses = '*'
wal_level = 'hot_standby'
archive_mode = on
archive_command = 'cd .'
max_wal_senders = 4
wal_keep_segments=8
synchronous_standby_names='beta'
_EOF1_
"

echo startowanie postgresa
sudo service postgresql start

exit 0

