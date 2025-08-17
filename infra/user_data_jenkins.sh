#!/bin/bash
set -eux

# Update base
yum update -y

# Java 17 for Jenkins LTS
amazon-linux-extras enable corretto17
yum install -y java-17-amazon-corretto

# Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
yum install -y jenkins

# Docker (for building images)
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker jenkins

# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/root/awscliv2.zip"
yum install -y unzip
unzip /root/awscliv2.zip -d /root
/root/aws/install

# Node.js 18 + git (helpers)
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git

systemctl enable jenkins
systemctl start jenkins
