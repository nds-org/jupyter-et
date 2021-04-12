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
