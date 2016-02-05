# Infrastructure provisioning for dstl-lighthouse

## Description

Code for provision and deployment for various components of the dstl-lighthouse project

## Usage

1. Create an ssh keypair in `jenkins/files/ssh_rsa`. These files are ignored by git
so you can't commit them (we hope).

2. `> vagrant up`

3. Access `http://10.1.1.10:8080`

## Jenkins

Bootstraps jenkins for the dstl-lighthouse project


