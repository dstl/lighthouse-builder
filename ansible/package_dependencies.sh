#!/bin/bash

result=0
lighthouse_ip="${LIGHTHOUSE_IP}"
environment="${ENVIRONMENT}"
inventory_file='/tmp/package-inventory'

render_inventory() {
  cat >$inventory_file << EOL
[package-lighthouse]
${lighthouse_ip} ansible_ssh_private_key_file=../secrets/preview.deploy.pem ansible_ssh_user=ec2-user

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
