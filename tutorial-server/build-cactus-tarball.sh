#!/bin/bash
set -ex

NCPUS=$(lscpu|grep '^CPU.s.:'|cut -d: -f2)

if [ "$USER" = "" ]
then
    export USER=etuser
    export HOME=/usr/etuser
fi

cd

# BUILD CACTUS
curl -kLO https://raw.githubusercontent.com/gridaphobe/CRL/${ET_RELEASE}/GetComponents
chmod a+x GetComponents
./GetComponents --parallel https://bitbucket.org/einsteintoolkit/manifest/raw/${ET_RELEASE}/einsteintoolkit.th
cd ~/Cactus
./simfactory/bin/sim setup-silent
#echo 'LIBDIRS = /lib/x86_64-linux-gnu' >> repos/simfactory2/mdb/optionlists/generic.cfg
export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu
./simfactory/bin/sim build -j$(($NCPUS/2)) --thornlist ../einsteintoolkit.th

ls ./exe/cactus_sim

# MAKE TARBALL
SED_IN_PLACE='t=$(stat -c %y "$0"); sed -i "s!'$PWD'!\$(CCTK_HOME)!g" "$0"; touch -d "$t" "$0"'

find configs/sim -name \*.d -exec bash -c "$SED_IN_PLACE" '{}' \;
find configs/sim -name \*.ccldeps -exec bash -c "$SED_IN_PLACE" '{}' \;
find configs/sim -name \*.deps -exec bash -c "$SED_IN_PLACE" '{}' \;
find configs/sim -name \*.defn -exec bash -c "$SED_IN_PLACE" '{}' \;

tar --exclude etk1.cct.lsu.edu.ini --exclude defs.local.ini -czf ../${PWD##*/}.tar.gz ../${PWD##*/}

cd
rm -fr Cactus CactusSourceJar.git  GetComponents  einsteintoolkit.th
