# Infrastructure provisioning for dstl-lighthouse

## Description

Code for provision and deployment for various components of the dstl-lighthouse project

## Requirements

* Vagrant
* VirtualBox (or VMware if you prefer)
* Terraform
* A keypair set up with AWS
* This repository and submodules pulled down

If you have the above, you can skip past "Getting started" to
[Provision server in AWS][provaws].

## Getting started

### Ensure SSH keys are set up for GitHub

In order to make changes to this repo you need to create an ssh keypair and add 
it to your GitHub profile. The easiest way to do this is by following
[this handy GitHub tutorial][ghssh].

### Clone the `lighthouse-builder` repo to your machine

```bash
git clone git@github.com:dstl/lighthouse-builder.git
cd lighthouse-builder
```

## Pull the `lighthouse-secrets` repo

The `lighthouse-secrets` repo is a private repo you should have access to.
It's a git submodule of this repo and contains files needed for lighthouse to
operate properly. If it has moved or you are using a different one, you can
change the `.gitmodules` file in this repo to point the new place. You need to
pull down the repo into the `secrets` directory, which can be done like so:

```bash
git submodule update --init
```

## Using Terraform

**Why would I use Terraform?** Terraform is used for provisioning cloud servers
on Amazon Web Services (AWS). It may at first seem daunting, but it can be a lot
easier and more productive than doing it through the AWS UI. All the
configuration for Lighthouse's AWS server is done in the `terraform` directory
of this repository.

### Create a keypair on AWS

Follow [this helpful guide provided by Amazon](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair)
in order to authenticate with AWS in the future, which is required for using
Terraform.

### Install Terraform

[Terraform][trfm] makes provisioning of cloud servers easy for AWS.

On a mac:

```bash
brew install terraform
```

For other platforms, you may be able to use the system package
manager, but it may be easier to download Terraform from the official
website on the [Terraform download page][trfmdl]. For more info on installing
and configuring terraform see [the guide to installing Terraform][trfminst]

### Provision servers in AWS

All the configuration files are located in `terraform`, so get your shell into
there first:

```bash
cd terraform
```

Then type 

```bash
terraform apply
```

Terraform will create the necessary resources in AWS. Check the AWS console and
you should see 2 servers provisioned.

### How to modify server details

The `terraform.tfvars` file contains the variables used by Terraform config to
change which network locations can access the Terraformed servers.

In `preview.tf`, each of the IP addresses listed in there are put into the
`ingress` block inside the `"aws_security_group"` resource.

This security group is used in `redhat_preview.tf`, in order to indicate which
IP addresses are able to access the Lighthouse server and the Lighthouse CI
server. `redhat_preview.tf` is also where these two servers are configured in
general, and is a good starting point for configuring new environments.

---

## How to Bootstrap Jenkins

Once the VMs are created in AWS you will need to bootstrap Jenkins before we
can get our CI pipeline running. By this point it is _vital_ that you have
pulled down the `lighthouse-secrets` repo.

Get the public IP of the Jenkins server from the AWS console. This IP will be
referred to as `jenkins-public-ip` in the following commands.

First step is to get this repo on to the Jenkins server from AWS. Rsync is the
suggested method. From the root of this repo, run the following.

```bash
rsync --recursive \
    -e 'ssh -i secrets/preview.deploy.pem' \
    . \
    centos@<jenkins-public-ip>:/tmp/bootstrap \
    --exclude-from "rsync_exclude.txt"
```

### Change the IP of the lighthouse host in site_specific

Edit the relevant site_specific.yml file. In this case we're hacking the
changes into the `preview.site_specific.yml` file. We should have a separate set
of files for a new AWS instance.

```bash
cd /tmp/bootstrap
vi preview.site-specific.yml
```

* Copy the IP of the lighthouse app box from the aws console and set the `lighthouse_host` parameter.

### Run the bootstrap command

```bash
ssh -i secrets/preview.deploy.pem centos@<jenkins-public-ip>
# You should now be in the Jenkins VM through SSH
(centos@ci) > cd /tmp/bootstrap/ansible
(centos@ci) > ./bootstrap.sh --preview
```

The bootstrap takes a few minutes. Then jenkins should be available at
[ci.lighthouse.pw].

### Update Jenkins

It's _vitally_ important to update jenkins through the internal update job
before trying to run any other jobs.
Run the `Update Jenkins` job from the dashboard.

### Restart Jenkins

Go to hit `http://<jenkins-public-ip>:8080/restart` to restart Jenkins. If and
when this doesn't work, try `ssh`ing onto the server (as described in "Run the
bootstrap command") and run:

```bash
(centos@ci) > sudo service jenkins restart
```

## Configuring your servers with `servers.yml`

The `servers.yml` file can be found in the `ansible` directory. It is
responsible for describing how Vagrant and Ansible should be provisioning and
setting up a new VM locally. It looks something like this:

```yaml
---
- name: lighthouse-dev
  box: box-cutter/centos72
  host: lighthouse.dev
  ip: 10.1.1.10
  ram: 1024
  playbook: playbook.yml
  mounts:
    - envvar: DSTL_LIGHTHOUSE
      target: /opt/lighthouse
  groups:
    - vagrant
    - development
```

Most of those yaml items are self-explanatory, but the important part is the
`groups` key. This contains a list of Ansible groups which this VM will fall
under, and thus determines which "plays" to run from the `playbook.yml` file
specified above.

## How does logging work?

Logging is done via uWSGI, and is configured in the Jinja2 template
`ansible/roles/dstl.lighthouse/templates/wsgi.ini.j2`. You should see this line:

```
daemonize={{ uwsgi_log_dir }}/lighthouse.log
```

When Ansible sets up uWSGI (using
`ansible/roles/digi2al.python/tasks/uwsgi.yml`), it'll use the `uwsgi_log_dir`
variable to point the logs at a specified location. The default, which is
configured in `ansible/roles/digi2al.python/defaults/main.yml`, is
`'/var/log/uwsgi'`

If you need to change the log location, your best bet is to do it on an
environmental level by changing the appropriate environment `.site_specific.yml`
file in the secrets folder.

## How is the Lighthouse server typically configured?

### Development

The Lighthouse application is written using Python+Django, and is executed
manually by using Django's usual management tools, `python manage.py runserver
0.0.0.0:3000`. Outside of the VM, that means the app will be available on the
VM's IP address (normally `10.1.1.10`) at port `3000`.

**Where is this configured/where does it happen?** In the `ansible` directory,
find `roles/digi2al.python/tasks`. Three tasks in there, `main.yml`, `nginx.yml`
and `uswsgi.yml` specify how the app is to be run.

### Production

The Lighthouse application is written using Python+Django, and is loaded using
an application server container called uWSGI. uWSGI loads the Django app
and serves it locally on an HTTP port (normally 8080).

**Where is this configured/where does it happen?** In the `ansible` directory,
find `roles/dstl.lighthouse/tasks` and `roles/digi2al.python/tasks`.

The tasks listed in `digi2al.python/tasks` will install `nginx` and `uWSGI`.

In `dstl.lighthouse/tasks`, users are set up, and config files are generated for
`nginx` and `uWSGI` from templates in the `digital.lighthouse/templates` folder.
The task which actually runs `nginx` and `uWSGI` using these new settings is
`service.yml`.

[ghssh]:https://help.github.com/articles/generating-an-ssh-key/
[provaws]:#provision-server-in-aws
[trfm]:https://www.terraform.io
[trfmdl]:https://www.terraform.io/downloads.html
[trfminst]:https://www.terraform.io/intro/getting-started/install.html
