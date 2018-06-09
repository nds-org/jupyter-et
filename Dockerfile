FROM jupyter/scipy-notebook

USER root

RUN apt-get -qq update && \
    apt-get -qq install python-matplotlib && \
    apt-get -qq install pkg-config build-essential mpich2? python libmpich2?-dev gfortran git subversion curl gnuplot gnuplot-x11 time && \
    apt-get -qq install libnuma-dev numactl hwloc libhwloc-dev libssl-dev hdf5-tools libhdf5-dev gdb gsl-bin libgsl0-dev ffmpeg autotools-dev&& \
    apt-get -qq install libgsl-dev libopenblas-dev libpapi-dev fftw3-dev &&\
    apt-get -qq clean all && \
    apt-get -qq autoclean && \
    apt-get -qq autoremove && \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER
ENV USER $NB_USER
COPY start-notebook.sh /usr/local/bin/
COPY CactusTutorial.ipynb /tutorial/
COPY hello.th qc0-mclachlan.th install_ET.sh /tutorial/
RUN bash /tutorial/install_ET.sh
USER root
RUN mv /home/$NB_USER/Cactus.tar /tutorials/
USER $NB_USER


CMD ["start-notebook.sh", "--NotebookApp.token=''"]
