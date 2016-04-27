# Infrastructure provisioning for dstl-lighthouse

## Description

Code for provision and deployment for various components of the dstl-lighthouse project

## Table of Contents

- [Requirements](#requirements)
- [Getting started](#getting-started)
  - [Ensure SSH keys are set up for GitHub](#ensure-ssh-keys-are-set-up-for-github)
  - [Clone the `lighthouse-builder` repo to your machine](#clone-the-lighthouse-builder-repo-to-your-machine)
  - [Pull the `lighthouse-secrets` repo](#pull-the-lighthouse-secrets-repo)
- [Provisioning](#provisioning)
  - [Using Terraform to provision](#using-terraform-to-provision)
    - [Create a keypair on AWS](#create-a-keypair-on-aws)
    - [Install Terraform](#install-terraform)
    - [Provision servers in AWS](#provision-servers-in-aws)
    - [How to modify server details](#how-to-modify-server-details)
- [Deploying](#deploying)
  - [Choose an Environment](#choose-an-environment)
    - [Criteria for choosing](#criteria-for-choosing)
      - [Internet access or air-gapped?](#internet-access-or-air-gapped)
      - [Preconfigured or Site Specific?](#preconfigured-or-site-specific)
    - [Preview](#preview)
    - [Copper](#copper)
    - [Bronze](#bronze)
    - [Silver](#silver)
  - [Configure settings](#configure-settings)
    - [Configure Preview](#configure-preview)
    - [Configure Copper](#configure-copper)
    - [Configure Bronze](#configure-bronze)
    - [Configure Silver](#configure-silver)
  - [Rsync dependencies](#rsync-dependencies)
    - [Dependencies for Internet bootstrap](#dependencies-for-internet-bootstrap)
    - [Dependencies for Airgapped bootstrap](#dependencies-for-airgapped-bootstrap)
  - [Bootstrap Jenkins](#bootstrap-jenkins)
    - [Bootstrap an Internet enabled deploy](#bootstrap-an-internet-enabled-deploy)
      - [Prerequisites for internet deploy](#prerequisites-for-internet-deploy)
      - [Bootstrap from /tmp/bootstrap](#bootstrap-from-tmpbootstrap)
    - [Bootstrap an Airgapped deploy](#bootstrap-an-airgapped-deploy)
      - [Prerequisites for Airgapped deploy](#prerequisites-for-airgapped-deploy)
      - [Bootstrap from /opt/dist/bootstrap](#bootstrap-from-optdistbootstrap)
  - [Update Jenkins](#update-jenkins)
  - [Restart Jenkins](#restart-jenkins)
  - [Deploy Lighthouse](#deploy-lighthouse)
- [Package dependencies](#package-dependencies)
  - [Overview of `/opt/dist`](#overview-of-optdist)
  - [Steps to collecting dependencies](#steps-to-collecting-dependencies)
- [Jenkins jobs](#jenkins-jobs)
  - [Build Lighthouse Job](#build-lighthouse-job)
  - [Build Lighthouse PRs job](#build-lighthouse-prs-job)
  - [Deploy Lighthouse job](#deploy-lighthouse-job)
  - [Acceptance Test Lighthouse job](#acceptance-test-lighthouse-job)
  - [Package Dependencies job](#package-dependencies-job)
  - [Update Jenkins job](#update-jenkins-job)
- [Configuring your servers with `servers.yml`](#configuring-your-servers-with-serversyml)
- [How does logging work?](#how-does-logging-work)
- [How is the Lighthouse server typically configured?](#how-is-the-lighthouse-server-typically-configured)
  - [Development](#development)
  - [Production](#production)

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

### Pull the `lighthouse-secrets` repo

The `lighthouse-secrets` repo is a private repo you should have access to.
It's a git submodule of this repo and contains files needed for lighthouse to
operate properly. If it has moved or you are using a different one, you can
change the `.gitmodules` file in this repo to point the new place. You need to
pull down the repo into the `secrets` directory, which can be done like so:

```bash
git submodule update --init
```

## Provisioning

### Using Terraform to provision

**Why would I use Terraform?** Terraform is used for provisioning cloud servers
on Amazon Web Services (AWS). It may at first seem daunting, but it can be a lot
easier and more productive than doing it through the AWS UI. All the
configuration for Lighthouse's AWS server is done in the `terraform` directory
of this repository.

#### Create a keypair on AWS

Follow [this helpful guide provided by Amazon][amzkeypair] in order to
authenticate with AWS in the future, which is required for using Terraform.

#### Install Terraform

[Terraform][trfm] makes provisioning of cloud servers easy for AWS.

On a mac:

```bash
brew install terraform
```

For other platforms, you may be able to use the system package
manager, but it may be easier to download Terraform from the official
website on the [Terraform download page][trfmdl]. For more info on installing
and configuring terraform see [the guide to installing Terraform][trfminst]

#### Provision servers in AWS

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

#### How to modify server details

The `terraform.tfvars` file contains the variables used by Terraform config to
change which network locations can access the Terraformed servers.

In `preview.tf`, each of the IP addresses listed in there are put into the
`ingress` block inside the `"aws_security_group"` resource.

This security group is used in `redhat_preview.tf`, in order to indicate which
IP addresses are able to access the Lighthouse server and the Lighthouse CI
server. `redhat_preview.tf` is also where these two servers are configured in
general, and is a good starting point for configuring new environments.

## Deploying

Deployments in Lighthouse are performed by Jenkins using Ansible.

It is important to understand the differences between the environments so you
can choose which one to deploy using.

**Steps to deploy**

- [Choose an environment](#choose-an-environment)
- [Configure settings](#configure-settings)
- [Rsync dependencies](#rsync-dependencies)
- [Bootstrap Jenkins](#bootstrap-jenkins)
- [Update Jenkins](#update-jenkins)
- [Restart Jenkins](#restart-jenkins)
- [Trigger Lighthouse Deploy](#deploy-lighthouse)

### Choose an Environment

|               | Has Internet Access | No Internet Access |
|---------------|---------------------|--------------------|
| Preconfigured | [Preview](#preview) | [Copper](#copper)  |
| Site Specific | [Bronze](#bronze)   | [Silver](#silver)  |

#### Criteria for choosing

##### Internet access or air-gapped?

Lighthouse is designed to be deployed into multiple different networks, some
airgapped and some with internet access. Whether you have internet access in
your network decides which [environment you should use](#choose-an-environment).

##### Preconfigured or Site Specific?

When deploying we have provided settings to "out-of-the-box" deploy to either
a Internet or Airgapped network. Should you need to deploy to another network
you can use Site Specific settings instead by using a [Bronze](#bronze) or
[Silver](#silver) evironment. Whether you need to configure these settings in
your network decides which [environment you should use](#choose-an-environment).


#### Preview

- **Has** internet access.
  Deploys using the internet and pulls all it's packages from public sources.
- **Preconfigured** settings.
  Requires only minimal [configuration before use](#configure-preview).

Preview has been preconfigured to deploy in AWS. It uses the layout created by
Terraform as defined in [terraform/preview.tf][previewtf]. You only need to
[configure a few settings](#configure-preview) before you can use it.

#### Copper

- **No** internet access.
  Requires all [dependencies to be packaged first](#package-dependencies).
- **Preconfigured** settings.
  Requires only minimal [configuration before use](#configure-copper).

Copper has been configured to deploy to AWS. It uses the layout created by
terraform as defined in [terraform/copper.tf][coppertf].

Copper requires an Internet enabled environment to have it's
[dependencies packaged](#package-dependencies) and these dependencies rsynced to
the target VM before it can
[bootstrap without internet access](#bootstrap-an-airgapped-deploy).

#### Bronze

- **Has** internet access.
  Deploys using the internet and pulls all it's packages from public sources.
- **Site specific** settings.
  Requires [configuring before use](#configure-bronze).

Bronze is more flexible version of Preview. As such it needs some 
[configuration before use](#configure-bronze).

#### Silver

- **No** internet access.
  Requires all [dependencies to be packaged first](#package-dependencies).
- **Site specific** settings.
  Requires [configuring before use](#configure-silver).

Silver is more flexible version of Copper. As such it needs some 
[configuration before use](#configure-silver).

Silver requires an Internet enabled environment to have it's
[dependencies packaged](#package-dependencies) and these dependencies rsynced to
it before it can [bootstrap without internet access](#airgapped-bootstrap).

### Configure settings

Settings need to be configured before [bootstrapping jenkins](#bootstrap-jenkins).
What needs configured depends greatly on which environment you've chosen to run.

#### Configure Preview

- **In `secrets/preview.inventory` set the internal IP of lighthouse**

    Use the Public IP of the lighthouse box created by terraform.

        [lighthouse-app-server]
        <public lighthouse ip> ansible_ssh_private_key_file=../secrets/preview.deploy.pem ansible_ssh_user=ec2-user

- **In `secrets/preview.site_specific.yml` set the lighthouse ip**

    Use the Public IP of the lighthouse box created by terraform.

        lighthouse_ip: '<public lighthouse ip>'

- **Commit those changes to master**
  
    Update jobs use master to update from so you need to commit these changes
    otherwise they will be overwritten when you update jenkins.

#### Configure Copper

- **In `secrets/copper.inventory` set the internal IP of lighthouse**

    Use the Public IP of the lighthouse box created by terraform.

        [lighthouse-app-server]
        <public lighthouse ip> ansible_ssh_private_key_file=../secrets/preview.deploy.pem ansible_ssh_user=ec2-user

- **In `secrets/copper.site_specific.yml` set the lighthouse ip**

    Use the Public IP of the lighthouse box created by terraform.

        lighthouse_ip: '<public lighthouse ip>'

- **Commit those changes to master**
  
    Update jobs use master to update from so you need to commit these changes
    otherwise they will be overwritten when you update jenkins.

#### Configure Bronze

Bronze requires a number of files to be created in `/opt/secrets` on the VM you
intend to bootstrap.

- **If using RHEL Make sure your VM is registered**

    Our deployments require unrestricted yum access. So ensuring your VM is
    fully registered with RHEL guarantees we can install things from yum.

- **Place an ssh private key that has rights to lighthouse**

    We put ours in `/opt/secrets/ssh.pem`. Use that path anywhere you are asked
    for `<ssh key path>` in this section.

- **Place a github ssh keypair in `/opt/secrets/ssh_rsa`**

    This ssh keypair is used to clone repos from github. The files need to be
    placed in `/opt/secrets/ssh_rsa` and `/opt/secrets/ssh_rsa.pub` and be owned
    by the `<ssh user>` you will use to bootstrap jenkins.

- **Create `/opt/secrets/site_specific.yml`**

        lighthouse_hostname: '<lighthouse url>'
        lighthouse_host: '<lighthouse url>'
        jenkins_url: 'http://<jenkins url>:8080/'
        lighthouse_ci_hostname: '<jenkins url>'
        jenkins_internal_url: 'http://0.0.0.0:8080/'
        github_token: '<github access token>'
        lighthouse_ip: '<lighthouse public ip>'
        lighthouse_secret_key: '<secret key>'
        lighthouse_ssh_key_path: '<ssh key path>'
        lighthouse_ssh_user: '<ssh user>'

    where:

    `<lighthouse url>`: The url you want users to access lighthouse over. Needs
    to be defined in DNS.

    `<jenkins url>`: The url you want to use to access jenkins. Needs to be
    defined in DNS.

    `<lighthouse ip>`: The IP of lighthouse that jenkins can use to ssh to.

    `<github token>`: A github personal access token which has access to
    lighthouse and lighthouse-builder.

    `<secret key>`: Some long random string used for crypto.
    Use `head -30 /dev/urandom | sha256sum` to generate a nice long random
    string.

    `<ssh key path>`: Path to the ssh private key that has `ssh` rights to the
    lighthouse VM, e.g. `/opt/secrets/ssh.pem`

    `<ssh user>`: The user that the `<ssh key path>` has to ssh in to lighthouse
    as. In preview this is `ec2-user`.

- **Create `/opt/secrets/bronze.inventory`**

        [lighthouse-app-server]
        <lighthouse ip> ansible_ssh_private_key_file=<ssh key path> ansible_ssh_user=<ssh user>

        [bronze:children]
        lighthouse-app-server

    where:

    `<lighthouse ip>`: The IP of lighthouse that jenkins can use to ssh to.

    `<ssh key path>`: Path to the ssh private key that has `ssh` rights to the
    lighthouse VM, e.g. `/opt/secrets/ssh.pem`

    `<ssh user>`: The user that the `<ssh key path>` has to ssh in to lighthouse
    as. In preview this is `ec2-user`.

#### Configure Silver

Silver requires a number of files to be created in `/opt/secrets` on the VM you
intend to bootstrap.

- **If using RHEL Make sure your VM is registered**

    Our deployments require unrestricted yum access. So ensuring your VM is
    fully registered with RHEL guarantees we can install things from yum.

- **Place an ssh private key that has rights to lighthouse**

    We put ours in `/opt/secrets/ssh.pem`. Use that path anywhere you are asked
    for `<ssh key path>` in this section.

- **Create `/opt/secrets/site_specific.yml`**

        lighthouse_hostname: '<lighthouse url>'
        lighthouse_host: '<lighthouse url>'
        jenkins_url: 'http://<jenkins url>:8080/'
        lighthouse_ci_hostname: '<jenkins url>'
        jenkins_internal_url: 'http://0.0.0.0:8080/'
        github_token: '<github access token>'
        lighthouse_ip: '<lighthouse public ip>'
        lighthouse_secret_key: '<secret key>'
        lighthouse_ssh_key_path: '<ssh key path>'
        lighthouse_ssh_user: '<ssh user>'

    where:

    `<lighthouse url>`: The url you want users to access lighthouse over. Needs
    to be defined in DNS.

    `<jenkins url>`: The url you want to use to access jenkins. Needs to be
    defined in DNS.

    `<lighthouse ip>`: The IP of lighthouse that jenkins can use to ssh to.

    `<github token>`: A github personal access token which has access to
    lighthouse and lighthouse-builder.

    `<secret key>`: Some long random string used for crypto.
    Use `head -30 /dev/urandom | sha256sum` to generate a nice long random
    string.

    `<ssh key path>`: Path to the ssh private key that has `ssh` rights to the
    lighthouse VM, e.g. `/opt/secrets/ssh.pem`

    `<ssh user>`: The user that the `<ssh key path>` has to ssh in to lighthouse
    as. In preview this is `ec2-user`.

- **Create `/opt/secrets/silver.inventory`**

        [lighthouse-app-server]
        <lighthouse ip> ansible_ssh_private_key_file=<ssh key path> ansible_ssh_user=<ssh user>

        [silver:children]
        lighthouse-app-server

    where:

    `<lighthouse ip>`: The IP of lighthouse that jenkins can use to ssh to.

    `<ssh key path>`: Path to the ssh private key that has `ssh` rights to the
    lighthouse VM, e.g. `/opt/secrets/ssh.pem`

    `<ssh user>`: The user that the `<ssh key path>` has to ssh in to lighthouse
    as. In preview this is `ec2-user`.

### Rsync dependencies

#### Dependencies for Internet bootstrap

Preview and Bronze both pull dependencies from the public internet. As such the
only thing they need to start the bootstrap is the [lighthouse-builder] repo.

- **Clone the `lighthouse-builder` repo to your machine**

        ~ > git clone git@github.com:dstl/lighthouse-builder.git

- **Ensure `lighthouse-secrets` repo is checked out**

        ~ > cd lighthouse-builder
        ~/lighthouse-builder > git submodule update --init

- **Rsync the lighthouse-builder repo to the jenkins VM**

        ~ > rsync -Pav -e 'ssh -i <ssh key path>' ~/lighthouse-builder/ /tmp/boostrap/

    where:

    `<ssh key path>` is the path to an ssh private key that can ssh in to the
    jenkins VM. For preview we use `secrets/preview.deploy.pem`.

    we assume you have checked out lighthouse-builder to `~/lighthouse-builder`.

#### Dependencies for Airgapped bootstrap

Copper and Silver both require full dependencies to be packaged on an existing
Internet enabled network.

- **Perform a full deploy to a Preview or Bronze environment**

    This is a full deploy, so it may take a while.

- **Package the dependencies on your Preview or Bronze**

    Follow the [guide to package dependencies](#package-dependencies).

- **Rsync dependencies from the Preview or Bronze jenkins VM**

        ~ > rsync -Pav -e 'ssh -i <ssh key path>' \
                  <ssh user>@<jenkins ip>:/opt/dist/ \
                  /tmp/dist/

    where:

    `<ssh key path>` is the path to an ssh private key that can ssh in to the
    jenkins VM. For preview we use `secrets/preview.deploy.pem`.

    `<ssh user>` is the user that `<ssh key path>` has to login as on jenkins.

    `<jenkins ip>` is the public IP of the jenkins VM.

- **Create the folder `/opt/dist` in the Copper or Silver jenkins VM**

        ~ > ssh -i <ssh key path>' <ssh user>@<target ip>
        <ssh user>@<target ip> > sudo mkdir /opt/dist/
        <ssh user>@<target ip> > sudo chmod <ssh user>:<ssh user> /opt/dist/
        <ssh user>@<target ip> > exit
        ~ >

    where:

    `<ssh key path>` is the path to an ssh private key that can ssh in to the
    jenkins VM. For preview we use `secrets/preview.deploy.pem`.

    `<ssh user>` is the user that `<ssh key path>` has to login as on jenkins.

    `<target ip>` is the public IP of the Copper or Silver jenkins VM.

- **Rsync dependencies to the Copper or Silver jenkins VM**

        ~ > rsync -Pav -e 'ssh -i <ssh key path>' \
                  /tmp/dist/ \
                  <ssh user>@<jenkins ip>:/opt/dist/

    where:

    `<ssh key path>` is the path to an ssh private key that can ssh in to the
    jenkins VM. For preview we use `secrets/preview.deploy.pem`.

    `<ssh user>` is the user that `<ssh key path>` has to login as on jenkins.

    `<jenkins ip>` is the public IP of the jenkins VM.

### Bootstrap Jenkins

#### Bootstrap an Internet enabled deploy

##### Prerequisites for internet deploy

Before doing this be sure you have:

- [Provisioned your VMs](#provisioning)
- [Rsynced dependencies for Internet deploy](#dependencies-for-internet-bootstrap)
- Configured a [Preview](#configure-preview) or [Bronze](#configure-bronze)
  environment

##### Bootstrap from /tmp/bootstrap

We assume you have this repo rsynced to `/tmp/bootstrap` in the target VM. If
not follow the guide to 
[rsync dependencies for Internet deploy](#dependencies-for-internet-bootstrap).

Run the following commands to `ssh` in to the target VM and perform the
bootstrap.

```bash
~ > ssh -i <ssh key path> <ssh user>@<target ip>
# You should now be in the Jenkins VM through SSH
(<ssh user>@<target ip>) > cd /tmp/bootstrap/ansible
(<ssh user>@<target ip>) > ./bootstrap.sh --<environment>
```

where:

`<environment>` is the environment you have chosen to deploy, either of
[preview](#preview) or [bronze](#bronze). Read the guide on 
[choosing an environment](#choose-an-environment) to decide which to use.

`<target ip>` is the IP of the target VM you want to bootstrap in to a Jenkins VM.

`<ssh key path>` is the path on your local machine to an ssh private key with
ssh rights to the target VM.

`<ssh user>` is the user that has rights to ssh in to the target VM

The bootstrap takes a few minutes. Once complete you will have a fully built
jenkins instance available at `<jenkins ip>`. Next you should 
[update jenkins](#update-jenkins) and [restart jenkins](#restart-jenkins) before
trying any deploys.

#### Bootstrap an Airgapped deploy

##### Prerequisites for Airgapped deploy

Before doing this be sure you have:

- [Provisioned your VMs](#provisioning)
- [Rsynced dependencies for Airgapped deploy](#dependencies-for-airgapped-bootstrap)
- Configured a [Copper](#configure-copper) or [Silver](#configure-silver)
  environment

##### Bootstrap from /opt/dist/bootstrap

We assume you have all dependencies rsynced to `/opt/dist` in the target VM. If
not follow the guide to 
[rsync dependencies for Airgapped deploy](#dependencies-for-airgapped-bootstrap).

Run the following commands to `ssh` in to the target VM and perform the
bootstrap.

```bash
~ > ssh -i <ssh key path> <ssh user>@<target ip>
# You should now be in the Jenkins VM through SSH
(<ssh user>@<target ip>) > cd /opt/dist/bootstrap/ansible
(<ssh user>@<target ip>) > ./bootstrap.sh --<environment>
```

where:

`<environment>` is the environment you have chosen to deploy, either of
[copper](#copper) or [silver](#silver). Read the guide on 
[choosing an environment](#choosing-an-environment) to decide which to use.

`<target ip>` is the IP of the target VM you want to bootstrap in to a Jenkins VM.

`<ssh key path>` is the path on your local machine to an ssh private key with
ssh rights to the target VM.

`<ssh user>` is the user that has rights to ssh in to the target VM

The bootstrap takes a few minutes. Once complete you will have a fully built
jenkins instance available at `<jenkins ip>`. Next you should 
[update jenkins](#update-jenkins) and [restart jenkins](#restart-jenkins) before
trying any deploys.

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

### Deploy Lighthouse

Once you have a fully working jenkins deploy, either Internet enabled or
Airgapped, the last step is to actually deploy the Lighthouse app.

To do this simply trigger a [Build Lighthouse job](#build-lighthouse-job) from
the Jenkins job list. This will, if it completes cleanly, trigger a full deploy
to the VM you defined when [configuring jenkins](#configure-settings).

## Package dependencies

To bootstrap Jenkins in a network that is airgapped we first need to collect all
the dependencies needed in bootstrapping and deploying.

### Overview of `/opt/dist`

Once [dependencies are collected](#steps-to-collecting-dependencies) are ready
you will have them all collected in `/opt/dist` on the Jenkins VM:

* **`/opt/dist/bootstrap`**

  The [lighthouse-builder] repo fully checked out and ready to be used to
  bootstrap Jenkins on your airgapped VM.

* **`/opt/dist/git`**

  The [lighthouse] and [lighthouse-builder] repos bare cloned so you can develop in
  the airgapped network.

* **`/opt/dist/jpi`**

  The Jenkins plugins that are installed by the [digi2al.jenkins][jnknsrole]
  ansible role.

* **`/opt/dist/pypi`**

  The Python libraries that are installed either by [lighthouse] or the
  [ansible roles]. This includes Python 3 and Python 2.7 libraries.

* **`/opt/dist/tars`**

  The [digi2al.phantomjs role][phntmjsrole] installs phantomjs from a tarball.
  This tarball is packaged in `/opt/dist/tars`.

* **`/opt/dist/workspaces`**

  Workspaces precreated for each of the Jenkins jobs. By checking out the
  workspaces we avoid the problems of checking out submodules and ensuring those
  submodules checkout from `/opt/dist`.

* **`/opt/dist/yum`**

  The numerous RPMs that are required to provision and configure both Jenkins
  and [lighthouse].

### Steps to collecting dependencies

The steps to this are:

* **Deploy a full Internet enabled environment**

  To collect the dependencies that are required to deploy the full environment
  we need a complete deployed environment. This environment will have all the
  dependencies already installed and so we can easily collect them.

  Follow the guide to
  [Bootstrap an Internet enabled deploy](#bootstrap-an-internet-enabled-deploy).

* **Run the Package Dependencies job**
  
  To collect dependencies from a fully deployed environment trigger the jenkins
  job "Package Dependencies". This job will:

  * SSH in to Lighthouse VM and collect installed *RPMs* and
    *PyPi Python libraries* to a folder in `/opt/dist` on the VM
  * Rsync the dependencies from the Lighthouse VM to `/opt/dist` on the
    Jenkins VM
  * Collect all installed *RPMs*, *PyPi libraries*, *Git repos* and
    *Jenkins plugins* to `/opt/dist` on the Jenkins VM
  * Pull a copy of this repo to `/opt/dist/bootstrap` so you can bootstrap
    Jenkins in the airgapped environment

* **Move the dependencies to the Airgapped Jenkins VM**
  
  In bootstrapping an airgapped environment we need to get the `/opt/dist`
  folder on to the target Jenkins VM. Our preferred transport mechanism is Rsync
  using a developer laptop as the bridge. Rsyncing between two environments using
  a laptop as the bridge is covered in the guide to
  [dependencies for an Airgapped bootstrap](#dependencies-for-airgapped-bootstrap).

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

## Jenkins jobs

### Build Lighthouse job

The Build Lighthouse job is used to ensure the correctness of the latest
deployable code of Lighthouse. It checks out the [lighthouse] repo and runs
Python unit tests using the script in [`bin/jenkins.sh`][jenkinsscript].

**With internet access** this job will download all dependencies from PyPi
and use them in running the tests. This is controlled by the ansible variable
`lighthouse_internet_access: yes`, which is the default.

**Without internet access** this job will use `/opt/dist/pypi` to fetch
dependencies from. This is controlled by the ansible variable
`lighthouse_internet_access: no`, which is defined in the
[digi2al.dependencies][depsrole] role.

It will trigger the [Deploy Lighthouse job](#deploy-lighthouse-job) if it passes.

### Build Lighthouse PRs job

The Build Lighthouse PRs job is identical to the Build Lighthouse job except it
will build branches other than master. This way we have the
[Build Lighthouse job](#build-lighthouse-job) to guarantee master is green while
this job flicks depending on the success of the different pull requests.

It will not trigger the [Deploy Lighthouse job](#deploy-lighthouse-job) if it
passes.

### Deploy Lighthouse job

The Deploy Lighthouse job checks out the [lighthouse-builder] repo and runs an
ansible playbook to deploy lighthouse. It uses the `lighthouse-app-server` group
defined in [`ansible/playbook.yml`][playbook] to perform the deploy.

**In Preview or Bronze** this job will download dependencies from the public
internet. This is controlled using the `distribute_dependencies: no` ansible var,
which is the default value.

**In Copper or Silver** this job will rsync dependencies from `/opt/dist` on the
Jenkins VM to `/opt/dist` on the Lighthouse VM. All dependencies will then be
consumed from `/opt/dist`.

It will trigger the [Acceptance Test Lighthouse job](#acceptance-test-lighthouse-job)
if it passes.

### Acceptance Test Lighthouse job

The Acceptance Test job checks out the [lighthouse] repo and runs the splinter
tests from [lighthouse/acceptancetests][accept] against the deployed instance of
lighthouse. This will prove that deployment was successful.

### Package Dependencies job

The Package Dependencies job runs two ansible plays, `package-lighthouse` and
`package-dependencies`, defined in [`ansible/playbook.yml`][playbook] by
checking out the [lighthouse-builder] repo and running
[`ansible/package-dependencies.sh`][pkgdepsscript].

Running this job will collect all dependencies needed to deploy lighthouse to
an airgapped network. See the guide on [Packaging](#package-dependencies) for
more about how this works.

### Update Jenkins job

The Update Jenkins job checks out the [lighthouse-builder] repo and runs an
ansible play, `jenkins`, defined in [`ansible/playbook.yml`][playbook].

Running this play will update Jenkins to the latest settings as defined by the
`jenkins` play.

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
[provaws]:#provision-servers-in-aws
[trfm]:https://www.terraform.io
[trfmdl]:https://www.terraform.io/downloads.html
[trfminst]:https://www.terraform.io/intro/getting-started/install.html
[amzkeypair]:http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair
[previewtf]: https://github.com/dstl/lighthouse-builder/blob/master/terraform/preview.tf
[coppertf]: https://github.com/dstl/lighthouse-builder/blob/master/terraform/copper.tf
[lighthouse-builder]: https://github.com/dstl/lighthouse-builder
[lighthouse]: https://github.com/dstl/lighthouse
[jnknsrole]: https://github.com/dstl/lighthouse-builder/tree/master/ansible/roles/digi2al.jenkins
[ansible roles]: https://github.com/dstl/lighthouse-builder/tree/master/ansible/roles
[phntmjsrole]: https://github.com/dstl/lighthouse-builder/tree/master/ansible/roles/digi2al.phantomjs
[depsrole]: https://github.com/dstl/lighthouse-builder/tree/master/ansible/roles/digi2al.dependencies
[playbook]: https://github.com/dstl/lighthouse-builder/tree/master/ansible/playbook.yml
[accept]: https://github.com/dstl/lighthouse/tree/master/acceptancetests
[pkgdepsscript]: https://github.com/dstl/lighthouse-builder/blob/master/ansible/package_dependencies.sh
[jenkinsscript]: https://github.com/dstl/lighthouse/blob/master/bin/jenkins.sh
