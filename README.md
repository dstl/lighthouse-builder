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

## Jenkins

Bootstraps jenkins for the dstl-lighthouse project

## Provision server in AWS 

How to provision a server in aws

cd terraform

create a terraform.tfvars file with your AWS credentials

access_key = "<YOUR AWS ACCESS KEY>"
secret_key = "<YOUR AWS SECRET ACCESS KEY>"

Then type 

$ terraform apply

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate

Outputs:

  aws_instace_ip = 52.49.140.210


