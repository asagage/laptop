#!/bin/sh

# This script bootstraps an OSX laptop to a point where we can run
# Ansible on localhost. It;
#  1. Installs 
#    - xcode
#    - ansible (via pip) 
#    - a few ansible galaxy playbooks  
#  2. Kicks off the ansible playbook
#    - main.yml
#
# It will ask you for your sudo password

# base install path
basedir='~/dev/asagage'

# current dir
cwd=$(pwd)

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

fancy_echo "Boostrapping ..."

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

# Here we go.. ask for the administrator password upfront and run a
# keep-alive to update existing `sudo` time stamp until script has finished
# sudo -v
# while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Ensure Apple's command line tools are installed
if ! command -v cc >/dev/null; then
  fancy_echo "Installing xcode ..."
  xcode-select --install 
else
  fancy_echo "Xcode already installed. Skipping."
fi

# setup our base dir
fancy_echo("Creating base dir if needed ...")
mkdir -p $basedir

if [ -d "$basedir/laptop" ]; then
  fancy_echo "Laptop repo dir exists. Removing ..."
  rm -rf $basedir/laptop/
fi
fancy_echo "Cloning laptop repo ..."
git clone https://github.com/asagage/laptop.git 

fancy_echo "Changing to laptop repo dir ..."
cd $basedir/laptop

# Install pip.
fancy_echo "Installing pip ..."
sudo easy_install pip

# Install Ansible.
fancy_echo "Installing Ansible ..."
sudo pip install ansible

# Add ansible.cfg to pick up roles path.
{ echo '[defaults]'; echo 'roles_path = ../'; } >> ansible.cfg

# Add an ansible hosts file.
sudo mkdir -p /etc/ansible
sudo touch /etc/ansible/hosts
echo -e '[local]\nlocalhost ansible_connection=local' | sudo tee -a /etc/ansible/hosts > /dev/null

# Install Roles
fancy_echo "Installing galaxy roles ..."
ansible-galaxy install --roles-path ./roles -r requirements.yml

# Check the role/playbook's syntax.
fancy_echo "Checking playbook syntax ..."
ansible-playbook main.yml --syntax-check

# Run this from the same directory as this README file. 
fancy_echo "Running ansible playbook ..."
ansible-playbook playbook.yml -i hosts -K -vvv 

fancy_echo "All set! Enjoy."