#!/bin/bash

echo "If you want to test the installation fresh, please create a fresh devcontainer."
read -p "Type 'yes' to proceed to install: " response
if [ "$response" != "yes" ]; then
	echo "Installation aborted."
	exit 1
fi

./install.sh "$@"