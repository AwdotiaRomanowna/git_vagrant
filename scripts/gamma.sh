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

# Lacznosc pomiedzy serwerami przez postgresa
echo -e "postgres\npostgres" | sudo passwd postgres
echo -e "\n\n\n\n" | sudo -u postgres bash -c ssh-keygen
su postgres <<'EOF'
echo -e "yes\npostgres" | ssh-copy-id 192.168.4.3
EOF

echo Zatrzymuje postgresa
sudo service postgresql stop

echo czyszczenie danych z PGDATA
sudo rm -rf /var/lib/postgresql/9.5/main

echo Kopiowanie danych z PGDATA
echo -e "000000" | sudo -u postgres pg_basebackup -h 192.168.4.3 -D /var/lib/postgresql/9.5/main -U replication -P -v -x

echo Tworzenie recovery.conf 
sudo -u postgres bash -c "cat >> /var/lib/postgresql/9.5/main/recovery.conf <<- _EOF1_
primary_conninfo = 'host=192.168.4.3 port=5432 user=replication password=000000'                                                                                                                                                             
standby_mode = 'on'
recovery_target_timeline = 'latest'
_EOF1_
"

sudo -u postgres bash -c "cat >> /etc/postgresql/9.5/main/postgresql.conf <<- _EOF2_
hot_standby = on
wal_level = hot_standby
max_wal_senders = 4
wal_keep_segments = 8
_EOF2_
"

echo startowanie postgresa
sudo service postgresql start

exit 0

