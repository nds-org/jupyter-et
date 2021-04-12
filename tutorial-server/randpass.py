import requests
import json

def longpass(n=10):
    r = requests.get("https://www.cct.lsu.edu/~sbrandt/passwds.php?json=true&num=%d" % n)
    return r.json()

def shortpass(n=10):
    r = requests.get("https://www.cct.lsu.edu/~sbrandt/passwds3.php?json=true&num=%d" % n)
    return r.json()


print("short:", shortpass(3))
print("long:",  longpass(3))
