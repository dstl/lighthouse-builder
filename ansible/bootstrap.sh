#!/bin/bash
# (c) Crown Owned Copyright, 2016. Dstl.

result=0
current_user="$(whoami)"
inventory_file='/tmp/bootstrap-inventory'
environment=''
app='jenkins'
use_dist=false

extra_pip_args=''

read -d '' local_repo << EOF
[local]
name=Local repo at /opt/dist/yum
baseurl=file:///opt/dist/yum
enabled=1
gpgcheck=0
protect=1
EOF

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
      --copper)
        environment='copper'
        use_dist=true
        extra_pip_args="--find-links=/opt/dist/pypi --no-index"
        shift;;
      --silver)
        environment='silver'
        use_dist=true
        extra_pip_args="--find-links=/opt/dist/pypi --no-index"
        shift;;
      --jenkins)
        app='jenkins'
        shift;;
      --lighthouse)
        app='lighthouse-app-server'
        shift;;
      --use-dist)
        use_dist=true
        extra_pip_args="--find-links=/opt/dist/pypi --no-index"
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

prepare_repo() {
  if $use_dist; then
    /bin/echo "Using local repo at /opt/dist"
    sudo rm -f /etc/yum.repos.d/*.repo
    sudo tee /etc/yum.repos.d/local.repo <<< "$local_repo"
  else
    /bin/rpm -q --quiet ius-release || (
      /bin/echo "Install IUS repo"
      /bin/curl -s https://setup.ius.io/ | sudo /bin/bash
    )
  fi
}

install_rpm() {
  /bin/rpm -q --quiet $1 || (/bin/echo "Install $1"; sudo /bin/yum -y install $1)
}

install_ansible() {
  install_rpm libffi-devel
  install_rpm gcc
  install_rpm python-devel
  install_rpm python-pip
  install_rpm openssl-devel
  sudo pip install ansible==2.1.1.0 $extra_pip_args
}

render_inventory() {
  sudo rm "$inventory_file"
  cat >$inventory_file << EOL
[${app}]
localhost ansible_connection=local ansible_user=$(whoami)

[$environment:children]
${app}
EOL
}

run_playbooks() {
  /bin/echo "Running Ansible playbooks"
  /bin/ansible-playbook playbook.yml -i $inventory_file
  (( result += $? ))
}

read_args $@

prepare_repo
install_ansible
render_inventory
run_playbooks

exit $result
