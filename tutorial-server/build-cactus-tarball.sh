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
cat > tutorial.cfg << EOF
# generic

# This option list is used internally by simfactory as a template during the
# sim setup and sim setup-silent commands
# Edit at your own risk

# Whenever this version string changes, the application is configured
# and rebuilt from scratch
VERSION = 2018-12-13

CPP = cpp
CC  = gcc
CXX = g++

FPP = cpp
F90 = gfortran

CPPFLAGS =
FPPFLAGS = -traditional

CFLAGS   = -g -std=gnu99
# if compiler is old and you do not need AMReX, can change to gnu++11
CXXFLAGS = -g -std=gnu++17
F90FLAGS = -g -fcray-pointer -ffixed-line-length-none

LDFLAGS = -rdynamic

DEBUG           = no
CPP_DEBUG_FLAGS =
C_DEBUG_FLAGS   =
CXX_DEBUG_FLAGS =

OPTIMISE           = yes
CPP_OPTIMISE_FLAGS =
C_OPTIMISE_FLAGS   = -O2
CXX_OPTIMISE_FLAGS = -O2
F90_OPTIMISE_FLAGS = -O2

PROFILE           = no
CPP_PROFILE_FLAGS =
C_PROFILE_FLAGS   = -pg
CXX_PROFILE_FLAGS = -pg
F90_PROFILE_FLAGS = -pg

WARN           = yes
CPP_WARN_FLAGS = -Wall
C_WARN_FLAGS   = -Wall
CXX_WARN_FLAGS = -Wall
F90_WARN_FLAGS = -Wall

OPENMP           = yes
CPP_OPENMP_FLAGS = -fopenmp
FPP_OPENMP_FLAGS = -D_OPENMP
C_OPENMP_FLAGS   = -fopenmp
CXX_OPENMP_FLAGS = -fopenmp
F90_OPENMP_FLAGS = -fopenmp

VECTORISE                = yes
VECTORISE_ALIGNED_ARRAYS = no
VECTORISE_INLINE         = yes

PTHREADS_DIR = NO_BUILD
ADIOS2_DIR = /usr/local
ADIOS2_INC_DIRS = /usr/local/include
ADIOS2_LIB_DIRS = /usr/local/lib
ADIOS2_LIBS = adios2_cxx11_mpi adios2_c_mpi adios2_core_mpi adios2_cxx11 adios2_c adios2_core

NSIMD_SIMD = SSE2
EOF
./simfactory/bin/sim build -j$(($NCPUS/2)) --thornlist ../einsteintoolkit.th --optionlist tutorial.cfg

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
