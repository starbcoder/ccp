#!/bin/bash

set -e

echo "Starting dependency installation..."

echo "Updating system packages..."
dnf update -y

echo "Installing httpd..."
dnf install -y httpd

echo "Creating web directory..."
mkdir -p /var/www/html

echo "Dependency installation completed successfully!"
