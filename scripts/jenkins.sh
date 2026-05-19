#!/bin/bash
# Jenkins Installation Script
# Ubuntu 24.04

sudo apt update -y
sudo apt install -y openjdk-17-jdk wget curl gnupg net-tools

wget https://get.jenkins.io/debian-stable/jenkins_2.504.1_all.deb
sudo dpkg -i jenkins_2.504.1_all.deb
sudo apt --fix-broken install -y

sudo systemctl enable jenkins
sudo systemctl restart jenkins
sudo systemctl status jenkins
