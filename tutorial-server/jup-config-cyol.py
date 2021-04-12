import pwd
import subprocess
import re
import os
from tornado.httpclient import HTTPError
import smtplib
import pprint
import base64
import hashlib

def codeme(m):
    t = type(m.lower())
    if t == str:
        m = m.encode()
    elif t == bytes:
        pass
    else:
        raise Exception(str(t))
    h = hashlib.md5(m)
    v = base64.b64encode(h.digest())
    s = re.sub(r'[\+/]','_', v.decode())
    return s[:-2]

def accept_user(user_id):
    try:
        r = requests.get('https://einsteintoolkit.org/tutorial-whitelist.txt')
    except:
        return None
    whitelist = r.text.split('\n')
    coded_user_id = codeme(user_id)
    if coded_user_id in whitelist:
        return True
    else:
        with open("/home/failed-log.txt", "a+") as fd:
            print(user_id, coded_user_id, file=fd)
        return False

pp = pprint.PrettyPrinter(indent=2)

with open("/users/relay.txt", "r") as fd:
    relay = fd.readline().strip()
    sender = fd.readline().strip()
    recip = fd.readline().strip().split(',')

def sendmail(body):
    message = "From: ETK Tutorial Admin <%s>\n" % sender
    message += "To: "+", ".join(recip)+"\n"
    message += "Subject: Tutorial Login Attempt\n"
    message += body
    smtpObj = smtplib.SMTP(relay)
    smtpObj.sendmail(sender, recip, message)

######
import requests
from tornado import gen, web

c.JupyterHub.authenticator_class = 'cyolauthenticator.CYOLAuthenticator'

# LSU does not allow TLSv1_1 or less
c.ConfigurableHTTPProxy.command = [
    'configurable-http-proxy', '--ssl-protocol=TLSv1_2'
]
def pre_spawn_hook(spawner):
    username = spawner.user.name
    try:
        pwd.getpwnam(username)
    except KeyError:
        subprocess.check_call(['useradd', '-g', 'users', '-ms', '/bin/bash', username])

c.Spawner.pre_spawn_hook = pre_spawn_hook

c.JupyterHub.template_paths = ['/jinja/templates']
c.CILogonOAuthenticator.scope = ['openid','email','org.cilogon.userinfo']

# To create your own certs
# openssl genrsa -out rootCA.key 2048
# openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem
#c.JupyterHub.ssl_cert = '/root/rootCA.pem'
#c.JupyterHub.ssl_key = '/root/rootCA.key'

c.JupyterHub.ssl_cert = '/etc/ssl/certs/etk.cct.lsu.edu.cer'
c.JupyterHub.ssl_key =  '/etc/ssl/private/etk.cct.lsu.edu.key'

c.JupyterHub.base_url = '/'
