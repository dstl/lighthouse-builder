#!/bin/bash
# (c) Crown Owned Copyright, 2016. Dstl.

result=0
lighthouse_ip="${LIGHTHOUSE_IP}"
environment="${ENVIRONMENT}"
inventory_file='/tmp/package-inventory'
ssh_private_key_path="${SSH_PRIVATE_KEY_PATH}"
ssh_user="${SSH_USER}"

render_inventory() {
  sudo rm "$inventory_file"
  cat >$inventory_file << EOL
[package-lighthouse]
${lighthouse_ip} ansible_ssh_private_key_file=${ssh_private_key_path} ansible_ssh_user=${ssh_user}

[package-dependencies]
localhost ansible_connection=local ansible_user=$(whoami)

[${environment}:children]
package-lighthouse
package-dependencies
EOL
}

run_playbooks() {
  /bin/echo "Running Ansible playbooks"
  /bin/ansible-playbook playbook.yml -i $inventory_file
  (( result += $? ))
}

render_inventory
run_playbooks

exit $result
