#!/bin/bash

link_file() {
  local src="$1"
  local dest="$2"

  if [[ -f "$src" ]]; then
    ln -s -f "$src" "$dest"
  else
    /bin/echo "$src not found. Exiting." 1>&2
    exit 1
  fi
}

prepare_secrets() {
  link_file /opt/secrets/site_specific.yml ./vars/site_specific.yml
  link_file /opt/secrets/ssh_rsa ./files/ssh_rsa
  link_file /opt/secrets/ssh_rsa.pub ./files/ssh_rsa.pub
}

require_root() {
  if [[ $EUID -ne 0 ]]; then
    /bin/echo "This script must be run as root" 1>&2
    exit 1
  fi
}

install_ansible() {
  /bin/rpm -q --quiet ius-release || ( /bin/echo "Install IUS repo" ; /bin/curl -s https://setup.ius.io/ | /bin/bash )
  /bin/rpm -q --quiet ansible || ( /bin/echo "Install Ansible" ; /bin/yum -y install ansible )
}

run_playbooks() {
  /bin/echo "Running Ansible playbooks"
  /bin/ansible-playbook bootstrap.yml
  /bin/ansible-playbook configure-jobs.yml
}

require_root

prepare_secrets
install_ansible
run_playbooks
