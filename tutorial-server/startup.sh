#!/bin/bash
# Make sure cron is running
randpass MND | grep pass: | cut -f2 -d: | sed 's/\s//g' > /usr/enable_mkuser
echo "STARTUP CODE:"
cat /usr/enable_mkuser

/etc/init.d/cron start >/dev/null 2>&1
cron /root/crontab.txt
cd /

python3 /usr/local/bin/make_users.py
if [ -r /home/shadow ]
then
    cp /home/shadow /etc/shadow
fi

jupyterhub --ip 0.0.0.0 --port 443 -f jup-config.py 2>&1 | tee /var/log/jup-log.txt
