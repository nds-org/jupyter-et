import os
import pwd
import subprocess
from traceback import print_exc

for uname in os.listdir("/home"):
    hm = "/home/"+uname
    ba = hm + "/.bashrc"
    if os.path.isdir(hm) and os.path.exists(ba):
        try:
            pwd.getpwnam(uname)
        except KeyError as ke:
            try:
              print("Handling KeyError")
              s = os.stat(hm)
              uid = str(s.st_uid)
              gid = "users"
              print("adding user:",uname,"uid:",uid)
              subprocess.check_call( \
                  ['useradd', '-g', gid, '-u', uid, '-ms', '/bin/bash', uname])
            except:
              print("Exception!")
              print_exc()
              print("Continuing...")
print("Done making users")
