# Infrastructure provisioning for dstl-lighthouse

## Description

Code for provision and deployment for various components of the dstl-lighthouse project

## Ensure you have your ssh keys setup for github

* Create a key on your box

* Put the public key up on github (settings, add key)

## Clone down the lighthouse-builder repo

		$> git clone git@github.com:dstl/lighthouse-builder.git
		$> cd lighthouse-builder

## Pull the secrets repo

		$> git submodule update --init

## Create a keypair on AWS


## Install Terraform

Terraform makes provisioning of cloud servers easy: https://www.terraform.io

On a mac:

		$> brew install terraform

## Provision server in AWS 

How to provision a server in aws

    > cd terraform

Then type 

    > terraform apply

Terraform will create the necessary resources in AWS. Check the AWS console and you should see 2 boxes.



## Boostrap Jenkins

Once the vms are created in AWS you will need to bootstrap Jenkins so we can
get our CI pipeline running.

Get the public IP of the jenkins server. Referred to as `jenkins-public-ip` in the following commands.

First step is to get this repo on to the jenkins server. Rsync is the suggested
method:

    > rsync --recursive \
            -e 'ssh -i secrets/preview.deploy.pem' \
            . \
            centos@<jenkins-public-ip>:/tmp/bootstrap \
            --exclude-from "rsync_exclude.txt"

## Change the IP of the lighthouse host in site_specific

* Edit the relevant site_specific.yml file. In this case we're hacking the changes into the `preview.site_specific.yml`
file. We should have a separate set of files for a new amazon instance.

	$> cd /tmp/bootstrap
	$> vi preview.site-specific.yml

* Copy the IP of the lighthouse app box from the aws console and set the `lighthouse_host` parameter.

## Run the boostrap command

    > ssh -i secrets/preview.deploy.pem centos@<jenkins-public-ip>
    centos@ci > cd /tmp/bootstrap/ansible
    centos@ci > ./bootstrap.sh --preview

The bootstrap takes a few minutes. Then jenkins should be available at
[ci.lighthouse.pw].

## Restart Jenkins

* Hit `http://<jenkins-public-ip>:8080/restart`

* or when this doesn't work, ssh onto the server and:

		$> sudo service jenkins restart

## Update Jenkins

It's important (vitally important) to update jenkins through the internal update
job before trying to run any other jobs.

Run the `Update Jenkins` job from the dashboard.

