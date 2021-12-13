#!/bin/bash

#PBS -l walltime=02:00:00
#PBS -l nodes=1:ppn=20
#PBS -A loni_cactus19

# module unload all
# module load gcc/6.4.0
# module load cuda/10.0

M4=$(which m4)
if [ "x${M4}" = x ]
then
  echo "No usable m4 command in path" >&2
  exit 1
fi

export NCPUS=$(lscpu|grep '^CPU.s.:'|cut -d: -f2)
export GMP_VER=${GMP_VER:-6.1.2}
export LZLIB_VER=${LZLIB_VER:-1.21}
export MPFR_VER=${MPFR_VER:-4.1.0}
export MPC_VER=${MPC_VER:-1.1.0}
export GCC_VER=${GCC_VER:-8.4.0}
export PARALLEL=$(($NCPUS/2))
export GCC_BUILD_DIR=/usr/local/build
export GCC_INSTALL_DIR=/usr/local

mkdir -p $GCC_BUILD_DIR
set -x
if [ ! -d $GCC_BUILD_DIR ]
then
  echo "Directory $GCC_BUILD_DIR does not exist."
  exit 2
fi

cd $GCC_BUILD_DIR
if [ ! -r lzip-${LZLIB_VER}.tar.gz ]
then
  curl -LO http://download.savannah.gnu.org/releases/lzip/lzip-${LZLIB_VER}.tar.gz
fi
if [ ! -d lzip-${LZLIB_VER} ]
then
  tar xzvf lzip-${LZLIB_VER}.tar.gz
fi

cd $GCC_BUILD_DIR
cd lzip-${LZLIB_VER}
export LZIP=$GCC_INSTALL_DIR/lzip-${LZLIB_VER}/bin/lzip
if [ ! -x $LZIP ]
then
  ./configure --prefix=$GCC_INSTALL_DIR/lzip-${LZLIB_VER}
  make -j ${PARALLEL} install
fi

cd $GCC_BUILD_DIR
if [ ! -r gmp-${GMP_VER}.tar.lz ]
then
  curl -LO https://gmplib.org/download/gmp/gmp-${GMP_VER}.tar.lz
fi
if [ ! -d gmp-${GMP_VER} ]
then
  $LZIP -d gmp-${GMP_VER}.tar.lz
  tar xf gmp-${GMP_VER}.tar
fi

cd $GCC_BUILD_DIR
GMP_DIR=${GCC_INSTALL_DIR}/gmp-${GMP_VER}
if [ ! -r ${GMP_DIR}/lib/libgmp.so ]
then
  cd gmp-${GMP_VER}
  ./configure --prefix=${GMP_DIR}
  make -j ${PARALLEL} install
fi

cd $GCC_BUILD_DIR
if [ ! -r mpfr-${MPFR_VER}.tar.gz ]
then
  curl -LO https://www.mpfr.org/mpfr-current/mpfr-${MPFR_VER}.tar.gz
fi
if [ ! -d mpfr-${MPFR_VER} ]
then
  tar xzf mpfr-${MPFR_VER}.tar.gz
fi

export MPFR_DIR=${GCC_INSTALL_DIR}/mpfr-${MPFR_VER}

cd $GCC_BUILD_DIR
if [ ! -r $MPFR_DIR/lib/libmpfr.so ]
then
  cd mpfr-${MPFR_VER}
  ./configure --prefix=${MPFR_DIR} --with-gmp=${GMP_DIR}
  make -j ${PARALLEL} install
fi

cd $GCC_BUILD_DIR
if [ ! -r mpc-${MPC_VER}.tar.gz ]
then
  curl -LO https://ftp.gnu.org/gnu/mpc/mpc-${MPC_VER}.tar.gz
fi
if [ ! -d mpc-${MPC_VER} ]
then
  tar xzf mpc-${MPC_VER}.tar.gz
fi

cd $GCC_BUILD_DIR
export MPC_DIR=${GCC_INSTALL_DIR}/mpc-${MPC_VER}
if [ ! -r ${MPC_DIR}/lib/libmpc.so ]
then
  cd mpc-${MPC_VER}
  ./configure --prefix=${MPC_DIR} --with-gmp=${GMP_DIR} --with-mpfr=${MPFR_DIR}
  make -j ${PARALLEL} install
fi

cd $GCC_BUILD_DIR
if [ ! -r gcc-${GCC_VER}.tar.gz ]
then
  curl -LO http://www.netgull.com/gcc/releases/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.gz
fi
if [ ! -d gcc-${GCC_VER} ]
then
  tar xzvf gcc-${GCC_VER}.tar.gz
fi

## NVPTX tools
## cd $GCC_BUILD_DIR
## if [ ! -d nvptx-tools ]
## then
##   git clone https://github.com/MentorEmbedded/nvptx-tools.git
## else
##   cd nvptx-tools
##   git pull
## fi

## export NVPTX_DIR=${GCC_INSTALL_DIR}/nvptx
## if [ ! -r $NVPTX_DIR/bin/nvptx-none-as ]
## then
##   cd $GCC_BUILD_DIR/nvptx-tools
##   ./configure --prefix=${NVPTX_DIR}
##   make -j ${PARALLEL}
##   make install
## fi

# See https://gcc.gnu.org/wiki/Offloading#A1._Building_accel_compiler
cd $GCC_BUILD_DIR
export GCC_DIR=${GCC_INSTALL_DIR}/gcc-${GCC_VER}
export LD_LIBRARY_PATH=${GMP_DIR}/lib:${MPFR_DIR}/lib:${MPC_DIR}/lib:${GCC_DIR}/lib
if [ ! -x ${GCC_DIR}/bin/gcc ]
then
  cd gcc-${GCC_VER}
  #./configure --prefix=${GCC_DIR} --with-gmp=$GMP_DIR --with-mpfr=$MPFR_DIR --with-mpc=$MPC_DIR --disable-multilib --target=nvptx-none --enable-as-accelerator-for=x86_64-pc-linux-gnu --with-build-time-tools=${NVPTX_DIR}/nvptx-none/bin --disable-sjlj-exceptions --enable-newlib-io-long-long
  ./configure --prefix=${GCC_DIR} --with-gmp=$GMP_DIR --with-mpfr=$MPFR_DIR --with-mpc=$MPC_DIR --disable-multilib
  ulimit -s 32768
  make -j ${PARALLEL} |& tee /usr/make-gcc.txt
  make install |& tee /usr/install-gcc.txt
fi

if [ -x ${GCC_DIR}/bin/gcc ]
then
  echo
  echo "*************** SUCCESS *******************"
  echo
  echo "Installation of gcc-${GCC_VER} successful."
  echo
  echo "To use set ..."
  echo "export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:\${LD_LIBRARY_PATH}"
  echo "export PATH=${GCC_DIR}/bin:\${PATH}"
fi
rm -fr $GCC_BUILD_DIR
if [ -x ${GCC_DIR}/bin/gcc ]
then
    exit 0
else
    echo build failed
    exit 1
fi
