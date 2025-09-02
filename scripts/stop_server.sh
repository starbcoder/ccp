#!/bin/bash

# stop_server.sh
# Script to stop httpd

echo "Checking if httpd is running..."
isExistApp=`pgrep httpd`
if [[ -n $isExistApp ]]; then
    echo "httpd is running, stopping it..."
    service httpd stop
    echo "httpd stopped successfully!"
else
    echo "httpd is not running"
fi
