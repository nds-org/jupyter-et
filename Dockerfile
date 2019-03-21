# It is possible to use a later version of Ubuntu,
# however, if one does that then a Singularity version
# of the image will not run on Shelob and other clusters
# with older linux kernels.
FROM ubuntu:16.04

USER root

# Including --no-install-recommends does help optimize
# the size of the image, but it makes it much harder to
# get the list of packages right. This list works.
RUN apt-get -qq update && \
    apt-get -qq install --no-install-recommends \
        build-essential python python3-pip gfortran git \
        subversion curl gnuplot gnuplot-x11 time libopenmpi-dev \
        libhdf5-openmpi-dev openmpi-bin \
        libnuma-dev numactl hwloc libhwloc-dev libssl-dev \
        hdf5-tools gdb gsl-bin libgsl0-dev python3-setuptools \
        ffmpeg libgsl-dev libopenblas-dev libpapi-dev fftw3-dev \
        liblapack-dev vim emacs24 nano openssh-client pkg-config && \
    apt-get -qq clean all && \
    apt-get -qq autoclean && \
    apt-get -qq autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip

# It is possible to install matplotlib and numpy using
# apt, unfortunately, one cannot install jupyter that
# way and the matplotlib builtin to ubuntu's apt system
# does not seem to work with jupyter. Numpy may not
# be needed, but if the users want to do any analysis
# in the notebook beyond following the script, they'll
# want to have it.
# pick jpupyterhub to match that of kubernetes jupyterhub chart which in its
# version 0.7.0 uses version 0.9.2 of jupyterhub
# this version requires python3
RUN pip3 install jupyter jupyterhub==0.9.2 matplotlib numpy
RUN rm -fr ~/.cache/pip*
ENV NB_USER jovyan
RUN useradd -m $NB_USER
USER $NB_USER
ENV USER $NB_USER
COPY start-notebook.sh /usr/local/bin/
COPY CactusTutorial.ipynb /tutorial/
USER root
RUN chmod a+rx -R /tutorial/ /usr/local/bin/start-notebook.sh
USER $NB_USER
ENV PKG_CONFIG_PATH /usr/share/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig

CMD ["start-notebook.sh", "--NotebookApp.token=''"]
