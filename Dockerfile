FROM jupyter/scipy-notebook

USER root

RUN apt-get update -y && \
    apt-get install -y sqlite3 libopencv-dev python-matplotlib && \
    apt-get install -y build-essential mpich2? python libmpich2?-dev gfortran git subversion curl gnuplot gnuplot-x11 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $NB_USER
COPY start-notebook.sh /usr/local/bin/

CMD ["start-notebook.sh", "--NotebookApp.token=''"]
