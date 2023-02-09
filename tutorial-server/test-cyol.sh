set -x
# To startup the server, the cert and key need
# to be generated. This script should take care of that.
bash ./mkcerts.sh

# Make sure the server is down
docker-compose -f docker-compose.local-cyol.yml down

# Bring up the cyol server in the background
docker-compose -f docker-compose.local-cyol.yml up -d

# Give it a chance to initialize
sleep 1

# Get the startup code from the logs. You'll
# need this to create a test user.
# Note that this server does NOT mount a volume.
# No data that you generate will persist.
docker-compose -f docker-compose.local-cyol.yml logs | grep 'STARTUP CODE:'
