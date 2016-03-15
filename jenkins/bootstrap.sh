#!/bin/bash

result=0
current_user="$(whoami)"

_is_vagrant=1
is_vagrant() {
  return $_is_vagrant
}
_is_preview=1
is_preview() {
  return $_is_preview
}
_is_bronze=1
is_bronze() {
  return $_is_bronze
}
_override_secrets=1
override_secrets() {
  return $_override_secrets
}

read_args() {
  while [[ $# > 0 ]]; do
    local key="$1"
    case $key in
      --vagrant)
        _is_vagrant=0
        shift;;
      --preview)
        _is_preview=0
        shift;;
      --bronze)
        _is_bronze=0
        shift;;
      --override-secrets)
        _override_secrets=0
        shift;;
      *)
        /bin/echo "Unknown option $key, ignoring." 1>&2
        shift;;
    esac
  done
}

install_ansible() {
  /bin/rpm -q --quiet ius-release || ( /bin/echo "Install IUS repo" ; /bin/curl -s https://setup.ius.io/ | sudo /bin/bash )
  /bin/rpm -q --quiet ansible || ( /bin/echo "Install Ansible" ; sudo /bin/yum -y install ansible )
  sudo pip install --upgrade ansible
}

run_playbooks() {
  /bin/echo "Running Ansible playbooks"
  /bin/ansible-playbook bootstrap.yml -i $ansible
  (( result += $? ))
}

read_args $@

install_ansible
run_playbooks

exit $result
