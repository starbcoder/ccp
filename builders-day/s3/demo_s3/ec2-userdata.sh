#!/bin/bash
sudo dnf -y update
sudo dnf -y install ruby
sudo dnf -y install wget
sudo dnf -y install httpd
cd /home/ec2-user
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto
