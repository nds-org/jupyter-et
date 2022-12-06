# This file can be run on an ET server for purposes of load testing.
# It will create artificial users with then name 'fakeetuser{n}' and
# run the CactusTutorial.ipynb notebook for all the fake users in
# parallel. It will then create a log file in each user's home directory.
from time import time
from subprocess import call
import threading
import sys
import argparse

def username(n):
    return f"fakeetuser{n}"

def pcall(args):
    print("call:",args)
    return call(args)

class wdir:
    def __enter__(self,d):
        self.here = os.getcwd()
        os.chdir(d)
    def __exit__(self,t,v,x):
        os.chdir(self.here)

def check_output(user):
    strs = [
        "INFO (HelloWorld): Hello World!",
        "Done creating cactus_sim.",
        "All done !",
        "7 components checked out successfully.",
        "0 components updated successfully.",
        "Terminating due to cctk_final_time"
    ]

    found = {}

    try:
        with open(f"/home/{user}/CactusTutorial.html","r") as fd:
            for line in fd.readlines():
                for s  in strs:
                    if s in line:
                        found[s] = True
    except Exception as e:
        print(e)
        return False

    for s in strs:
        if s not in found:
            print(f"String '{s}' not found for user {user}")

    return len(found) == len(strs)

def create_user(user):
    print(f"Starting Worker '{user}'")
    pcall(["useradd","-m","-s","/bin/bash",user])
    pcall(["rm","-fr",f"/home/{user}/Cactus"])
    script = f"/home/{user}/run.sh"
    with open(script,"w") as fd:
        print("set -x",file=fd)
        print("cd",file=fd)
        print("pwd",file=fd)
        print("jupyter nbconvert --to html --execute CactusTutorial.ipynb",file=fd)
    t1 = time()
    pcall(["su","-",user,script])
    t2 = time()

    success = check_output(user)

    with open(f"/home/{user}/tut.log","w") as fd:
        print("Time:",t2-t1,file=fd)
        print("Success:",success,file=fd)
    print(f"Finishing worker '{user}",t2-t1, success)

class Worker(threading.Thread):
    def __init__(self,n):
        threading.Thread.__init__(self)
        self.n = n
    def run(self):
        create_user(username(self.n))

parser = argparse.ArgumentParser(prog='load-test', description='The ET Tutorial Server Load-Tester')
parser.add_argument('--check-only', action='store_true', default=False, help='Only check that the output is correct.')
parser.add_argument('--num-users', type=int, default=5, help='The number of fake user accounts to generate/test.')
args=parser.parse_args(sys.argv[1:])

if args.check_only:
    fail_count = 0
    for i in range(args.num_users):
        user = username(i)
        success = check_output(user)
        print(f"check_ouptut({user}) => {success}")
        if not success:
            fail_count += 1
    exit(fail_count)

workers = []

for i in range(args.num_users):
    w = Worker(i)
    w.start()
    workers += [w]

for w in workers:
    w.join()
