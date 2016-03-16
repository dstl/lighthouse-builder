#!/bin/bash

result=0
current_user="$(whoami)"
inventory_file='/tmp/bootstrap-inventory'
environment=''

read_args() {
  while [[ $# > 0 ]]; do
    local key="$1"
    case $key in
      --vagrant)
        environment='vagrant'
        shift;;
      --preview)
        environment='preview'
        shift;;
      --bronze)
        environment='bronze'
        shift;;
      *)
        /bin/echo "Unknown option $key, Exiting." 1>&2
        exit 1
        shift;;
    esac
  done
  if [[ -z $environment ]]; then
    /bin/echo "No environment provided, Exiting." 1>&2
    exit 1
  fi
}

install_ansible() {
  /bin/rpm -q --quiet ius-release || ( /bin/echo "Install IUS repo" ; /bin/curl -s https://setup.ius.io/ | sudo /bin/bash )
  /bin/rpm -q --quiet ansible || ( /bin/echo "Install Ansible" ; sudo /bin/yum -y install ansible )
  sudo pip install --upgrade ansible
}

render_inventory() {
  cat >$inventory_file << EOL
[jenkins]
localhost ansible_connection=local

[$environment:children]
jenkins
EOL
}

run_playbooks() {
  /bin/echo "Running Ansible playbooks"
  /bin/ansible-playbook bootstrap.yml -i $inventory_file
  (( result += $? ))
}

read_args $@

install_ansible
render_inventory
run_playbooks

exit $result
