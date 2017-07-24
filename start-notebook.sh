#!/bin/bash
set -e

#if [ ! -d ~/work/data ]; then
#   ln -s /data ~/work/
#fi 
#
#if [ ! -d ~/work/tutorials ]; then
#   git clone https://github.com/terraref/tutorials.git ~/work/tutorials
#fi 


source activate python2

. /usr/local/bin/start.sh jupyter notebook $*
