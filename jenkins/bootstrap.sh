#!/bin/bash

# Make sure only root can run our script

if [[ $EUID -ne 0 ]]; then
   /bin/echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ -f "/opt/site_specific.yml" ]]; then
  cp /opt/site_specific.yml ./vars/site_specific.yml
else
  /bin/echo "/opt/site_specific.yml not found. Exiting." 1>&2
  exit 1
fi

/bin/rpm -q --quiet ius-release || ( /bin/echo "Install IUS repo" ; /bin/curl -s https://setup.ius.io/ | /bin/bash )


/bin/rpm -q --quiet ansible || ( /bin/echo "Install Ansible" ; /bin/yum -y install ansible )

/bin/echo "Running Ansible playbooks"
/bin/ansible-playbook bootstrap.yml
/bin/ansible-playbook configure-jobs.yml
