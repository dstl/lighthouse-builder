# Infrastructure provisioning for dstl-lighthouse

## Description

Code for provision and deployment for various components of the dstl-lighthouse project

## Usage

1. Create an ssh keypair in `jenkins/files/ssh_rsa`. These files are ignored by git
so you can't commit them (we hope).

2. `> cp jenkins/vars/example.site_specific.yml jenkins/vars/site_specific.yml` and
add to it the URL jenkins will be deployed under and a github personal access token.

Go here: https://github.com/settings/tokens/new and create a token with `repo` and
`admin:repo_hook`.

3. `> vagrant up`

4. Access `http://10.1.1.10:8080`

## Provision server in AWS 

How to provision a server in aws

    > cd terraform

Then type 

    > terraform apply

Terraform will create the necessary resources in AWS.

## Boostrap Jenkins

Once the vms are created in AWS you will need to bootstrap Jenkins so we can
get our CI pipeline running.

First step is to get this repo on to the jenkins server. Rsync is the suggested
method:

    > rsync --recursive \
            -e 'ssh -i secrets/preview.deploy.pem' \
            . \
            centos@ci.lighthouse.pw:/tmp/bootstrap \
            --exclude-from "rsync_exclude.txt"

With our folder rsynced across we can now ssh in and run the bootstrap:

    > ssh -i secrets/preview.deploy.pem centos@ci.lighthouse.pw
    centos@ci > cd /tmp/bootstrap/jenkins
    centos@ci > ./bootstrap.sh --preview --override-secrets

The bootstrap takes a few minutes. Then jenkins should be available at
[ci.lighthouse.pw].

## Update Jenkins

It's important (vitally important) to update jenkins through the internal update
job before trying to run any other jobs.

Run the Update Jenkins job from the dashboard.
