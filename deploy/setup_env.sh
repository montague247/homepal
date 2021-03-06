#!/usr/bin/env bash
# Copyright (c) Dirk Helbig. All rights reserved.
#

# Stop script on NZEC
set -e
# Stop script if unbound variable found (use ${var:-} if intentional)
set -u
# By default cmd1 | cmd2 returns exit code of cmd2 regardless of cmd1 success
# This is causing it to fail
set -o pipefail

# install ansible
#  - install .NET 6 or newer
#  - install Apache WebServer
#  - install certbot: https://certbot.eff.org/instructions?ws=apache&os=debianbuster
#  - install Elastic Search

echo "Setup environment '$OSTYPE'..."

sudo apt update
apt list --upgradable
sudo apt upgrade -y
sudo apt install ansible -y

echo "Installed ansible version:"
ansible --version

echo "Environment is up-2-date"
