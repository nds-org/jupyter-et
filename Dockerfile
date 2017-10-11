FROM jupyter/scipy-notebook

USER root

RUN echo "deb http://ftp.uk.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \
    apt-get -qq update && \
    apt-get -qq install sqlite3 libopencv-dev python-matplotlib && \
    apt-get -qq install build-essential mpich2? python libmpich2?-dev gfortran git subversion curl gnuplot gnuplot-x11 time && \
    apt-get -qq install libnuma-dev numactl hwloc libhwloc-dev libssl-dev hdf5-tools libhdf5-dev gdb gsl-bin libgsl0-dev ffmpeg autotools-dev&& \
    apt-get -qq install libgsl-dev libopenblas-dev libpapi-dev fftw3-dev &&\
    apt-get -qq clean all && \
    apt-get -qq autoclean && \
    apt-get -qq autoremove && \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER
ENV USER $NB_USER
COPY start-notebook.sh /usr/local/bin/

CMD ["start-notebook.sh", "--NotebookApp.token=''"]
