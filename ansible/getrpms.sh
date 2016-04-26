#!/bin/bash
# (c) Crown Owned Copyright, 2016. Dstl.

for DIST in CentOS Redhat
do
  mkdir -p ${WORKSPACE}/stable/$DIST/7/x86_64/
  rsync -avH --numeric-ids --delete --exclude 'debug*' --exclude 'repo*' rsync://lon.mirror.rackspace.com/ius/stable/${DIST}/7/x86_64/ ${WORKSPACE}/stable/${DIST}/7/x86_64/
  createrepo ${WORKSPACE}/stable/$DIST/7/x86_64/
done
