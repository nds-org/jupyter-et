#!/bin/bash

set -e -x

cd /home/$USER

if false; then # the LSU svn server is down
curl -kLO https://raw.githubusercontent.com/gridaphobe/CRL/ET_2018_02/GetComponents
chmod a+x GetComponents

./GetComponents /tutorial/hello.th
# pass in "no" to avoid updaing anything and get an automated script
./GetComponents /tutorial/qc0-mclachlan.th <<<no
else # use tarball on my workstation instead
curl http://141.142.41.4/Cactus-UNAM.tar.gz | tar -xz
fi

cd Cactus

./simfactory/bin/sim setup-silent

./simfactory/bin/sim build hello --mdbkey make 'make -j2' --thornlist thornlists/hello.th

./simfactory/bin/sim build qc0 --mdbkey make 'make -j2' --thornlist thornlists/qc0-mclachlan.th

cd ..
tar -cf Cactus.tar Cactus
rm -rf Cactus
