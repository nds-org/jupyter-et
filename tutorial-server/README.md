# ET Tutorial Server

Configuration

Create "variables.env" with an entry like this one:

    OAUTH_CALLBACK_URL=https://etk.cct.lsu.edu/hub/oauth_callback
    OAUTH_CLIENT_ID=...
    OAUTH_CLIENT_SECRET=...

For email, configure the relay server in users/relay.txt

    relay.lsu.edu
    sender@lsu.edu
    recipient1@lsu.edu,recipient2@lsu.edu,...

For ssl, configure

# Building things

    # base image
    docker-compose -f docker-compose.base.yml build --pull

    # user image and also tutorial server
    docker-compose -f docker-compose.notebook.yml build

    # cilogon, only needed by server
    touch variables.env
    docker-compose -f docker-compose.cilogon.yml build
    docker-compose -f docker-compose.cyol.yml build

# Test the server locally
    
    bash ./test-cyol.sh
    # Note the code will display as the system starts up.

# Test the notebook locally

    docker-compose -f docker-compose.notebook.yml down
    docker volume rm tutorial-server_home_nbfs
    docker-compose -f docker-compose.notebook.yml up -d
    docker-compose -f docker-compose.notebook.yml logs

# Clean up leftover files from prior tests

    docker volume rm tutorial-server_home_nbfs
