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
    m = m.lower()
    t = type(m)
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
        r = requests.get('https://einsteintoolkit.org/tutorials-whitelist.txt')
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
from oauthenticator.github import GitHubOAuthenticator
from oauthenticator.cilogon import CILogonOAuthenticator
from oauthenticator import OAuthCallbackHandler
import requests
from tornado import gen, web

# this is needed to allow logins by non-education identity providers that
# do not have the eppn field
# RH (2019-03-20) this does not work since jupyterhub is too old
# c.CILogonOAuthenticator.additional_username_claim = 'email'
c.CILogonWhitelistAuthenticator.additional_username_claims = ['eppn', 'oidc']
c.CILogonOAuthenticator.username_claim = 'email'

class GitHubWhitelistAuthenticator(GitHubOAuthenticator):
 
    def check_whitelist(self, username):
        return accept_user(username)

class CILogonWhitelistCallbackHandler(OAuthCallbackHandler):

    @gen.coroutine
    def get(self):
      self.check_arguments()
      # copied from _login_user_pre_08
      data = {}
      user_info = yield self.authenticator.get_authenticated_user(self, data)
      if user_info is None:
        if 'bad_login' in data:
          with open("/home/bad-login.txt", "a+") as fd:
              print(data['bad_login_full'],file=fd)
          err = web.HTTPError(403, "%s is not authorized", data['bad_login'])
          if "gmail.com" in data["email"] and "Google" == data["org"]:
              err.my_message = "New gmail accounts are not currently being accepted from the Google organization. Please use your university account or github."
          else:
              err.user_info = {
                  "name":data["name"],
                  "email":data["email"],
                  "org":data["org"]
              }
              err.my_message = """
<p>
If you have already been notified that your account has been activated, and you are still having trouble, please make sure you are using the correct CILogon login option used in your account creation. If this still does not work, then please contact the maintainers at maintainers@einsteintoolkit.org providing the full text of the message above.
</p>
          """
          raise err
        else:
          raise web.HTTPError(403)
      username = user_info['name']
      user = self.user_from_username(username)
      self.set_login_cookie(user)
      self.redirect(self.get_next_url(user))

class CILogonWhitelistAuthenticator(CILogonOAuthenticator):
 
    fname = "/home/name_map.txt"

    def normalize_username(self, name):

        self.log.info("normalize: "+str(name))
        user_to_full = {}
        full_to_user = {}

        if os.path.exists(self.fname):
            with open(self.fname,"r") as fd:
                for line in fd.readlines():
                    g = re.match(r'^(\w+):(.*)', line)
                    user = g.group(1)
                    full = g.group(2)
                    if g:
                        user_to_full[user] = full
                        full_to_user[full] = user

        if name in full_to_user:
            return full_to_user[name]

        g = re.match(r'^https?:.*/(.*)', name)
        if g:
            name = 'user'+re.sub(r'-','',g.group(1))

        g = re.match(r'^\w+', name)
        user = g.group(0)
        if re.match(r'^\d', user):
            user = 'user'+user
        full = name
        if user not in user_to_full:
            pass
        else:
            while True:
                # Does the username already end with a number? increment it.
                # Otherwise, append 0.
                g = re.match(r'(.*\D)(\d+)', user)
                if g:
                    user = g.group(1)+str(int(g.group(2))+1)
                else:
                    user = user + "0"
                if user not in user_to_full:
                    break
        with open(self.fname, "a") as fd:
            fd.write(user+":"+full+"\n")
        os.chmod(self.fname, 0o0600);
        return user

    # new versions of jupyterhub would pass userdict to the check_whitelist
    # function making this much easier
    @gen.coroutine
    def authenticate(self, handler, data=None):
        import traceback
        userdict = yield super(CILogonWhitelistAuthenticator, self).authenticate(handler, data)
        if userdict is None:
            return None
        #self.log.info("auth_state: %s" % repr(userdict))
        #yyy
        self.log.info("STATE:"+str(userdict['auth_state']))

        # copied from jupyterhub/auth.py
        username = self.normalize_username(userdict['name'])

        # the identity provider name as it appears on https://cilogon.org/
        idp_name = userdict['auth_state']['cilogon_user']['idp_name']

        # the full name
        full_name = userdict['auth_state']['cilogon_user'].get('name', username)

        # email
        email = userdict['auth_state']['cilogon_user'].get('email')

        # is this an educational institution (we trust them)
        ePPN = userdict['auth_state']['cilogon_user'].get('eppn')

        if email is None:
            email = ePPN

        oidc = userdict['auth_state']['cilogon_user'].get('oidc')
        if email is None and idp_name == "ORCID":
            email = "user" + re.sub(r'-','',re.sub(r'.*/','',oidc))
            username = email

        if idp_name == "ORCID":
            full_name = oidc

        if email is None:
            raise web.HTTPError(403, \
                "%s does not have an email address", userdict['name'])

        # this makes the user name known to our caller
        data['bad_login_full'] = "'%s' who is '%s' from '%s' with email '%s'" % \
            (username, full_name, idp_name, email)
        data['bad_login'] = full_name
        data['name'] = full_name
        data['email'] = email
        data['org'] = idp_name

        # Not sure what this logic is here for
        #if not ePPN and idp_name != 'GitHub':
        #    return None

        if accept_user(email):
            return userdict

        return None

    callback_handler = CILogonWhitelistCallbackHandler

c.JupyterHub.authenticator_class = CILogonWhitelistAuthenticator
######

#c.ConfigurableHTTPProxy.debug = True
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
#c.JupyterHub.log_level = 'DEBUG'
#c.Spawner.debug = True
#c.LocalProcessSpawner.debug = True

# To create your own certs
# openssl genrsa -out rootCA.key 2048
# openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem
#c.JupyterHub.ssl_cert = '/root/rootCA.pem'
#c.JupyterHub.ssl_key = '/root/rootCA.key'

#c.JupyterHub.ssl_cert = '/etc/ssl/certs/etk.cct.lsu.edu.cer'
c.JupyterHub.ssl_cert = '/etc/ssl/certs/etk.cct.lsu.edu.cer'
c.JupyterHub.ssl_key =  '/etc/ssl/private/etk.cct.lsu.edu.key'
c.JupyterHub.ssl_ciphers =  'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384'

c.JupyterHub.base_url = '/'

# Required by LSU security
c.JupyterHub.tornado_settings = {
        "headers": {
          "Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
          "X-Frame-Options": "DENY",
          "X-Content-Type-Options": "nosniff",
          "X-XSS-Protection": "1; mode=block",
          "Content-Security-Policy": "frame-ancestors 'self'; report-uri /hub/security/csp-report; default-src 'self'"
        }
      }

