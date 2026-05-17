#!/bin/bash
# Download and setup only the translated s-ui.sh
wget -O /usr/bin/s-ui https://raw.githubusercontent.com/LaithAlYasiri601/s-ui-translated/main/s-ui.sh
chmod +x /usr/bin/s-ui
echo "Translated s-ui CLI has been installed to /usr/bin/s-ui"
echo "You can now run 's-ui' to manage your panel."
