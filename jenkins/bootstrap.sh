#!/bin/bash

is_vagrant=false
is_preview=false
is_bronze=false
override_secrets=false

read_args() {
  while [[ $# > 1 ]]; do
    local key="$1"
    case $key in
      --vagrant)
        is_vagrant=true
        shift;;
      --preview)
        is_preview=true
        shift;;
      --bronze)
        is_bronze=true
        shift;;
      --override-secrets)
        override_secrets=true
        shift;;
      *)
        /bin/echo "Unknown option $key, ignoring." 1>&2
        shift;;
    esac
  done
}

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
  local jenkins_update_target="$1"

  if is_vagrant; then
    link_file /opt/secrets/vagrant.site_specific.yml ./vars/site_specific.yml
  elif is_preview; then
    link_file /opt/secrets/preview.site_specific.yml ./vars/site_specific.yml
  elif is_preview; then
    link_file /opt/secrets/site_specific.yml ./vars/site_specific.yml
  else
    /bin/echo "Provide an update target: [--vagrant|--preview|--bronze]. Exiting."1>&2
    exit 1
  fi
  link_file /opt/secrets/ssh_rsa ./files/ssh_rsa
  link_file /opt/secrets/ssh_rsa.pub ./files/ssh_rsa.pub
}

update_secrets() {
  if override_secrets; then
    cp ../secrets /opt/secrets
  fi
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
read_args "$@"

update_secrets
prepare_secrets
install_ansible
run_playbooks
