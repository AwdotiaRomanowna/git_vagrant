#!/usr/bin/env bash

echo 'Start Beta'

# pobierz z apt.postgresql.org

echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main 9.5" > /etc/apt/sources.list.d/pgdg.list
wget -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | apt-key add -

# update 
apt-get update
apt-get -y -q install pgdg-keyring

# instalowanie postgresa
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
host    replication     replication     192.168.4.4/32   md5
_EOF1_
"

sudo service postgresql restart

# Tworze usera DB
psql -U postgres -c "CREATE USER replication REPLICATION LOGIN CONNECTION LIMIT 1 PASSWORD '000000';"

# Lacznosc pomiedzy serwerami przez postgresa
echo -e "postgres\npostgres" | sudo passwd postgres
echo -e "\n\n\n\n" | sudo -u postgres bash -c ssh-keygen
su postgres <<'EOF'
echo -e "yes\npostgres" | ssh-copy-id 192.168.4.4
EOF

echo Zatrzymuje postgresa
sudo service postgresql stop

echo czyszczenie danych z PGDATA
sudo rm -rf /var/lib/postgresql/9.5/main

echo Kopiowanie danych z PGDATA
echo -e "000000" | sudo -u postgres pg_basebackup -h 192.168.4.2 -D /var/lib/postgresql/9.5/main -U replication -P -v -x

echo Tworzenie recovery.conf 
sudo -u postgres bash -c "cat >> /var/lib/postgresql/9.5/main/recovery.conf <<- _EOF1_
primary_conninfo = 'host=192.168.4.2 port=5432 user=replication password=000000'                                                                                                                                                             
standby_mode = 'on'
recovery_target_timeline = 'latest'
_EOF1_
"

sudo -u postgres bash -c "cat >> /etc/postgresql/9.5/main/postgresql.conf <<- _EOF2_
archive_mode=on
listen_addresses = '*'
hot_standby = on
wal_level = hot_standby
max_wal_senders = 4
wal_keep_segments = 8
_EOF2_
"

echo startowanie postgresa
sudo service postgresql start

exit 0

