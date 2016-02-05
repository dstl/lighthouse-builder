#!/bin/bash

# Make sure only root can run our script

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "Installing IUS release repo"

curl -s https://setup.ius.io/ | bash

echo "Install Ansible"

yum -y install ansible

echo "Install jenkins"

ansible-playbook bootstrap.yml
