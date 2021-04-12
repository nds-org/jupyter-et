import os
import pwd
import subprocess

for uname in os.listdir("/home"):
    hm = "/home/"+uname
    ba = hm + "/.bashrc"
    if os.path.isdir(hm) and os.path.exists(ba):
        try:
            pwd.getpwnam(uname)
        except KeyError:
            s = os.stat(hm)
            uid = str(s.st_uid)
            gid = "users"
            print("adding user:",uname,"uid:",uid)
            subprocess.check_call( \
                ['useradd', '-g', gid, '-u', uid, '-ms', '/bin/bash', uname])
