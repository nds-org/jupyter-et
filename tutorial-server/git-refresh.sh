#!/bin/bash
# This script is to be called by cron in order to keep the notebooks updated
{
cd /jupyter-et
git pull
cp *.ipynb /tutorial/
cp *.ipynb /etc/skel/
} > /tmp/git-refresh.log 2>&1
