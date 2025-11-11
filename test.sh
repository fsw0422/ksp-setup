#!/bin/bash

echo "If you want to test everything from fresh, please remove the current running devcontainer image and recreate it."
read -p "Type 'yes' to proceed to install: " response
if [ "$response" != "yes" ]; then
    echo "Installation aborted."
    exit 1
fi

./install.sh "$@"