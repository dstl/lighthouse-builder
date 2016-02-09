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


