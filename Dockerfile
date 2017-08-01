FROM jupyter/scipy-notebook

USER root

RUN echo "deb http://ftp.uk.debian.org/debian jessie-backports main" >> /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get install -y sqlite3 libopencv-dev python-matplotlib && \
    apt-get install -y build-essential mpich2? python libmpich2?-dev gfortran git subversion curl gnuplot gnuplot-x11 time && \
    apt-get install -y libnuma-dev numactl hwloc libhwloc-dev libssl-dev hdf5-tools libhdf5-dev gdb gsl-bin libgsl0-dev ffmpeg autotools-dev&& \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER
ENV USER $NB_USER
COPY start-notebook.sh /usr/local/bin/
COPY .bashrc /home/jovyan/.bashrc

ENV HOME /home/jovyan/work
WORKDIR /home/jovyan/work
CMD ["start-notebook.sh", "--NotebookApp.token=''"]
