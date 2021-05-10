apt-get -y install vim sudo git certbot python3-pip python-certbot-nginx postgresql postgresql-client
useradd -md /opt/odoo odoo
apt-get -y install python3-dev libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev git python3-dev libpq-dev
echo 'set mouse-=a' > /root/.vimrc
echo 'set mouse-=a' > /home/emonge/.vimrc
#rm -r /opt/odoo
git clone --depth 1 --branch 14.0 https://github.com/odoo/odoo.git /opt/odoo
git clone --depth 1 --branch 14.0 https://github.com/EstebanMonge/l10n_cr.git /tmp/l10n_cr
echo 'set mouse-=a' > /opt/odoo/.vimrc
chown -R odoo.odoo /opt/odoo
cd /opt/odoo
sudo -u odoo pip3 install setuptools
sudo -u odoo pip3 install wheel
sudo -u odoo pip3 install -r requirements.txt
cd /tmp/l10n_cr
cp -R cr_electronic_invoice l10n_cr_country_codes cr_electronic_invoice_pos l10n_cr_hacienda_info_query res_currency_cr_adapter cr_electronic_invoice_qweb_fe /opt/odoo/addons/
sudo -u odoo pip3 install -r requirements.txt
mkdir /var/log/odoo
chown odoo:root /var/log/odoo
ipaddress=$(ip a|grep inet|grep -v '127\|inet6' | awk '{print $2}' | sed 's/\/24//')
sudo -u postgres createuser --createdb --username postgres --no-createrole --no-superuser odoo
sudo -u postgres psql -c '\x' -c 'ALTER USER odoo WITH SUPERUSER'
sudo -u postgres psql -c '\x' -c "ALTER USER odoo WITH PASSWORD 'odoo';"
sudo sed -i '/^host    replication     all             127.0.0.1\/32            md5/a host    all             all             192.168.122.0\/24        md5' /etc/postgresql/11/main/pg_hba.conf
sudo sed -i "s/= 'localhost/= 'localhost,$ipaddress/g" /etc/postgresql/11/main/postgresql.conf
sudo sed -i 's/#listen_addresses/listen_addresses/g' /etc/postgresql/11/main/postgresql.conf
sudo systemctl restart postgresql
sudo cat <<'EOF' >> /etc/odoo.conf
[options]
db_host = ipaddress
db_port = 5432
db_user = odoo
db_password = odoo
addons_path = /opt/odoo/addons
logfile = /var/log/odoo/odoo.log
EOF
sed -i "s/ipaddress/$ipaddress/g" /etc/odoo.conf
sudo chown odoo.odoo /etc/odoo.conf
sudo cat <<'EOF' >> /etc/systemd/system/odoo.service
[Unit]
Description=odoo
After=network.target

[Service]
User=odoo
Group=odoo
ExecStart=/usr/bin/python3 /opt/odoo/odoo-bin -c /etc/odoo.conf
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl start odoo
sudo systemctl enable odoo
