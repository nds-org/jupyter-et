FROM ubuntu:16.04

USER root

RUN apt-get -qq update && \
    apt-get -qq install \
        build-essential python python-pip gfortran git mpich2? \
        subversion curl gnuplot gnuplot-x11 time libmpich2?-dev \
        libnuma-dev numactl hwloc libhwloc-dev libssl-dev \
        hdf5-tools libhdf5-dev gdb gsl-bin libgsl0-dev \
        ffmpeg libgsl-dev libopenblas-dev libpapi-dev fftw3-dev \
        liblapack-dev vim openssh-client pkg-config && \
    apt-get -qq clean all && \
    apt-get -qq autoclean && \
    apt-get -qq autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip && \
    pip install matplotlib numpy jupyter && \
    rm -fr ~/.cache/pip
ENV NB_USER jovyan
RUN useradd -m $NB_USER
USER $NB_USER
ENV USER $NB_USER
COPY start-notebook.sh /usr/local/bin/
COPY CactusTutorial.ipynb /tutorial/
ENV PKG_CONFIG_PATH /usr/share/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig

CMD ["start-notebook.sh", "--NotebookApp.token=''"]
