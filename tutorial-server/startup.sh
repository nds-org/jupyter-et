#!/bin/bash
# Make sure cron is running
/etc/init.d/cron start >/dev/null 2>&1
cron /root/crontab.txt
cd /
python3 /usr/local/bin/make_users.py
jupyterhub --ip 0.0.0.0 --port 443 -f jup-config.py > /var/log/jup-log.txt 2>&1
