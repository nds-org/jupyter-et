#!/bin/bash
set -e

#if [ ! -d ~/work/data ]; then
#   ln -s /data ~/work/
#fi 
#
#if [ ! -d ~/work/tutorials ]; then
#   git clone https://github.com/terraref/tutorials.git ~/work/tutorials
#fi 


. /usr/local/bin/start.sh jupyter notebook $*
