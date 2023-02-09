set -x
if [ ! -r etc/ssl/certs/etk.cct.lsu.edu.cer -o ! -r etc/ssl/private/etk.cct.lsu.edu.key ]
then
    openssl genrsa -out rootCA.key 2048
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem < cert-info.txt

    mkdir -p etc/ssl/private
    cp rootCA.key etc/ssl/private/etk.cct.lsu.edu.key

    mkdir -p etc/ssl/certs
    cp rootCA.pem etc/ssl/certs/etk.cct.lsu.edu.cer
fi

#c.JupyterHub.ssl_cert = '/etc/ssl/certs/etk.cct.lsu.edu.cer'
#c.JupyterHub.ssl_key =  '/etc/ssl/private/etk.cct.lsu.edu.key'
#c.JupyterHub.ssl_ciphers =  'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384'
