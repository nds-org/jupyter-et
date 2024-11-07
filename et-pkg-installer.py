#!/usr/bin/env python

import os
import re
import sys

def get_pkg_cmd():
    for p in os.environ["PATH"].split(os.pathsep):
        for cmd in ["apt-get","dnf","yum","zypper"]:
            f = p+os.sep+cmd
            if os.path.exists(f):
                return cmd

pkg_cmd = get_pkg_cmd()

if pkg_cmd == None:
    raise Exception("Could not idenfity operating system")

# the next couple of dicts describe the required packages to compile the ET.
# Each entry uses a human-readable key for the softwre and then either a single
# string for the required packages or a list of strings or lists of acceptable
# sets of alternative packages.
# For example:
# "hdf5":"libhdf5-dev" means that the capability "hdf5" is provided by the
# package "libhdf5-dev".
# "mpi":[ "openmpi-devel", "mpich-devel", "mpich2-devel"] means that any of the
# packages "openmpi-devel", "mpich-devel" or "mpich2-devel" can be used to
# satisfy the "mpi" requirement.
# Finally:
# "mpi":[
#     ["libopenmpi-dev","libhdf5-openmpi-dev"],
#     ["libmpich-dev","libhdf5-mpich-dev"],
#     ["libmpich2-dev","libhdf5-mpich2-dev"]],
# states that any of the mpi+hdf5 pairs are acceptable to satisfy the MPI
# requirement. libhdf5 devel files appear b/c HDF5 optionally depends on MPI
# and can use the MPI version.

debk = {
    "perl":"perl",
    "gfortran":"gfortran",
    "gcc":"gcc",
    "g++":"g++",
    "papi":"libpapi-dev",
    "gsl":"libgsl-dev",
    "lapack":"liblapack-dev",
    "hdf5":"libhdf5-dev",
    "mpi":[
      ["libopenmpi-dev","libhdf5-openmpi-dev"],
      ["libmpich-dev","libhdf5-mpich-dev"],
      ["libmpich2-dev","libhdf5-mpich2-dev"]],
    "pkg-config":"pkg-config",
    "subversion":"subversion",
    "git":"git",
    "python":"python3",
    "patch":"patch",
    "make":"make",
    "numa":"numactl",
    "hwloc":[["libhwloc-dev","hwloc"]],
    "ssl":"libssl-dev",
    "fftw":"libfftw3-dev",
    "curl":"curl",
    "which":None,
    "rsync":"rsync",
    "tar":None,
    "hostname":None,
    "xargs":None,
    "jpeg":"libjpeg-turbo?-dev",
    "libtool":None,
    "libudev":"libudev-dev",
    }

redk = {
    "perl":"perl",
    "gfortran":"gcc-gfortran",
    "gcc":"gcc",
    "g++":"gcc-c++",
    "papi":"papi-devel",
    "gsl":"gsl-devel",
    "lapack":"lapack-devel",
    "hdf5":"hdf5-devel",
    "mpi":[
        ["openmpi-devel","hdf5-openmpi-devel"], 
        ["mpich-devel","hdf5-mpich-devel"],
        ["mpich2-devel","hdf5-mpich2-devel"]],
    "pkg-config":"pkgconfig",
    "subversion":"subversion",
    "git":"git",
    "python":"python",
    "patch":"patch",
    "make":"make",
    "numa":"numactl-devel",
    "hwloc":"hwloc-devel",
    "ssl":"openssl-devel",
    "fftw":"fftw-devel",
    "curl":"curl",
    "which":"which", # Used by simfactory
    "rsync":"rsync",
    "tar":None,
    "hostname":"hostname",
    "xargs":"findutils",
    "jpeg":"libjpeg-turbo-devel",
    "libtool":"libtool-ltdl-devel", # Needed to link on this platform
    "libudev":None,
    }

susek = {
    "perl":"perl",
    "gfortran":"gcc-fortran",
    "gcc":"gcc",
    "g++":"gcc-c++",
    "papi":"papi-devel",
    "gsl":"gsl-devel",
    "lapack":"lapack-devel",
    "hdf5":"hdf5-devel",
    "mpi":[
        "openmpi-devel",
        "mpich-devel",
        "mpich2-devel"],
    "subversion":"subversion",
    "pkg-config":"pkg-config",
    "git":"git",
    "python":"python",
    "patch":"patch",
    "make":"make",
    "numa":"libnuma-devel",
    "hwloc":"hwloc-devel",
    "ssl":"libopenssl-devel",
    "fftw":"fftw3-devel",
    "curl":"curl",
    "which":"which",
    "hostname":"hostname",
    "rsync":"rsync",
    "tar":"tar",
    "xargs":None,
    "jpeg":"libjpeg8-devel",
    "libtool":None,
    "libudev":None,
    }

cmds = {
    "perl":"perl",
    "gfortran":"gfortran",
    "gcc":"gcc",
    "g++":"g++",
    "papi":None,
    "gsl":None,
    "lapack":None,
    "hdf5":None,
    "mpi":None,
    "pkg-config":"pkg-config",
    "subversion":"svn",
    "git":"git",
    "python":"python",
    "patch":"patch",
    "make":"make",
    "numa":None,
    "hwloc":None,
    "ssl":None,
    "fftw":None,
    "curl":"curl",
    "which":"which",
    "rsync":"rsync",
    "tar":"tar",
    "hostname":"hostname",
    "xargs":"xargs",
    "jpeg":None,
    "libtool":None,
    "libudev":None,
    }

# Check that both tables have the same keys
def check(h1,h2):
    for k in h1:
        assert k in h2, k
    for k in h2:
        assert k in h1, k

check(debk,redk)
check(redk,susek)
check(redk,cmds)

install_cache = {}

# The kcmd or "key command" parameter is the
# name of the package installed. Frequently,
# this is the same as a linux shell command.
# When that is the case, one can search the
# path for the command in question rather tha
# querying a package manager.
def installed1(kcmd,cmd):
    global install_cache
    if type(cmd) == list:
        install_count = 0
        missing = []
        for c in cmd:
            res = installed1(kcmd,c);
            install_count += res["installed"]
            missing += res["missing"]
        return {"installed":install_count,"missing":missing}
            
    if cmds[kcmd] is not None:
        for path in os.environ["PATH"].split(":"):
            path = re.sub(r'/+$','',path)
            if os.path.exists(path+'/'+cmds[kcmd]):
                return {"installed":1,"missing":[]}
        return {"installed":0,"missing":[cmd]}

    if pkg_cmd == "apt-get":
        if cmd in install_cache:
            return install_cache[cmd]
        ex = (os.system("dpkg -s "+cmd) == 0)
        install_cache[cmd] = ex
        if ex:
            return {"installed":1,"missing":[]}
    if pkg_cmd == "yum" or pkg_cmd == "dnf" or pkg_cmd == "zypper":
        if install_cache == {}:
            install_cache = {}
            for pkg in os.popen("rpm -qa"):
                one_pkg = re.sub("-[^-]+-[^-]+$","",pkg)
                install_cache[one_pkg]=1
        if cmd in install_cache:
            return {"installed":1,"missing":[]}
    return {"installed":0,"missing":[cmd]}

def installed(kcmd,cmd):
    if type(cmd) == str:
        return installed1(kcmd,cmd)
    elif type(cmd) == list:
        answer = None
        for c in cmd:
            res = installed1(kcmd,c)
            nin = len(res["missing"])
            ins = res["installed"]
            if nin==0:
                return res
            elif answer == None:
                answer = res
            elif ins > answer["installed"]:
                answer = res
            elif ins == answer["installed"] and nin < len(answer["missing"]):
                answer = res
        return answer
    return {"installed":0,"missing":[]}

pkgs = None
if pkg_cmd == "apt-get":
    pkgs = debk
elif pkg_cmd == "dnf" or pkg_cmd == "yum":
    pkgs = redk
elif pkg_cmd == "zypper":
    pkgs = susek
else:
    raise Exception("No package manager")

if pkgs == None:
    raise Exception("Could not determine what packages to install")

def install():
    answer={"installed":0,"missing":[]}

    fd = open("install-for-cactus.sh","w")

    for k in pkgs:
        p = pkgs[k]
        res = installed(k,p)
        answer["installed"] += res["installed"]
        answer["missing"] += res["missing"]

    if len(answer["missing"]) == 0:
        fd.write("# All packages are installed\n")
    else:
        # Special thing for Centos
        if os.path.exists("/etc/centos-release"):
            epel = installed("epel-release", None)
            if len(epel["missing"]) > 0:
                fd.write(pkg_cmd+" install -y epel-release\n")

    first = True
    for c in answer["missing"]:
        if type(c) == str:
            if type(c) == str:
                if first:
                    first = False
                    fd.write(pkg_cmd)
                    fd.write(" install -y")
                fd.write(' ')
                fd.write(c)
            elif type(c) == list:
                for cc in c:
                    if first:
                        first = False
                        fd.write(pkg_cmd)
                        fd.write(" install -y")
                    fd.write(' ')
                    fd.write(cc)
        else:
            raise Exception()
    fd.write("\n")
    fd.close()
    sys.stdout.write("Install file 'install-for-cactus.sh' has been written\n")

def gets(c,k):
    pre = c+" install -y "
    if type(k) == str:
        return pre+k
    elif type(k) == list:
        if type(k[0]) == list:
            return " ".join(k[0])
        elif type(k[0]) == str:
            return pre+k[0]
        else:
            raise Exception()
    elif type(k) == type(None):
        return "&nbsp;"
    else:
        raise Exception(str(type(k)))

if __name__ == "__main__":
    if len(sys.argv)>1 and sys.argv[1] == "--table":
        fd = open("install-for-cactus.html","w")
        fd.write("<table>\n");
        fd.write("<tr><th>Package</th><th>Debian/Mint/Ubuntu</th>"+
            "<th>fedora</th><th>centos</th><th>opensuse</th></tr>\n")
        for k in debk:
           fd.write('<tr>')
           fd.write("<td>"+k+"</td>")
           fd.write("<td>"+gets("apt-get",debk[k])+"</td>")
           fd.write("<td>"+gets("dnf",redk[k])+"</td>")
           fd.write("<td>"+gets("yum",redk[k])+"</td>")
           fd.write("<td>"+gets("zypper",susek[k])+"</td>")
           fd.write("</tr>\n")
        fd.write("</table>\n")
        fd.close()
        sys.stdout.write("Install file 'install-for-cactus.html' has been written\n")
    else:
        install()
