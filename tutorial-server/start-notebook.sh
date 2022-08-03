#!/bin/bash
set -e

# only start notebook if not inside of the etkhub container which starts the
# notebook on its own
cd
export PORT=8888
SECRET_TOKEN=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;)
echo "Copying missing notebooks"
cp -van /etc/skel/*.ipynb ~/

echo
echo "To access the notebook, open this file in a browser copy and paste this URL:"
echo
echo " http://localhost:$PORT/?token=${SECRET_TOKEN}"
echo
jupyter notebook $* --ip 0.0.0.0 --port $PORT --no-browser --NotebookApp.token="${SECRET_TOKEN}"
