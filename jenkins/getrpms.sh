#!/bin/bash

/bin/mkdir -p RPMS
/bin/yum -y -q reinstall --downloadonly --downloaddir=RPMS python35u python35u-pip python35u-devel python35u-setuptools python35u-libs
