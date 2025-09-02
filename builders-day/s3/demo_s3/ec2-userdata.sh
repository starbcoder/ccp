#!/bin/bash
sudo dnf -y update
sudo dnf -y install ruby
sudo dnf -y install wget
sudo dnf -y install httpd
cd /home/ec2-user
wget https://aws-codedeploy-us-west-2.s3.us-west-2.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto