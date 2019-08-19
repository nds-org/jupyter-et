#!/bin/bash
set -e

BASHRC_TEMPLATE_PATH="/etc/skel/.bashrc"
BASHRC_PATH="$HOME/.bashrc"

# If user doesn't already have a local .bashrc file
if [ ! -f "$BASHRC_PATH" ]; then
    # Copy the skeleton .bashrc file
    echo "Copying base .bashrc file to $BASHRC_PATH"
    cp $BASHRC_TEMPLATE_PATH $BASHRC_PATH

    # Set an alias for python2 to use that by default instead
    echo ""
    echo "# Comment this line and restart shell to use Python 3" >> $BASHRC_PATH
    echo "alias python='python2'" >> $BASHRC_PATH
fi

# Copy the tutorial notebook if it doesn't exist
if [ ! -f "$HOME/work/CactusTutorial.ipynb" ]; then
    mkdir -p $HOME/work/
    cp /tutorial/*.ipynb $HOME/work/
fi

# only start notebook if not inside of the etkhub container which starts the
# notebook on its own
PORT=8888
if [ -z "$JUPYTERHUB_USER" ];then
  cd ~/work
  SECRET_TOKEN=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)
  echo
  echo "To access the notebook, open this file in a browser copy and paste this URL:"
  echo
  echo " http://localhost:$PORT/?token=${SECRET_TOKEN}"
  echo
  jupyter notebook $* --ip 0.0.0.0 --port $PORT --no-browser --NotebookApp.token="${SECRET_TOKEN}"
fi
