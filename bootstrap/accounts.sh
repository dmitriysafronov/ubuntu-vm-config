#!/bin/bash

source ~/.ubuntu-vm-config

if [[ -z "${ACCOUNT_EMERGENCY}" || -z "${ACCOUNT_MAINTENANCE}" ]]; then
	clear; echo "Export SSH keys fisrt!"
	exit 1
fi

export ANSIBLE_HOME='/var/lib/ansible'

#######

chattr -i /root/.ssh 2> /dev/null
chattr -i /root/.ssh/authorized_keys 2> /dev/null
rm -r /root/* /root/.* 2> /dev/null
cp -rT /etc/skel /root
mkdir -p /root/.ssh
echo "${ACCOUNT_EMERGENCY}" > /root/.ssh/authorized_keys
chown -R root:root /root
chmod 0700 /root/.ssh
chmod 0600 /root/.ssh/authorized_keys
if [[ -n "$(which restorecon)" ]]; then restorecon -Rv /root/.ssh; fi
chattr +i /root/.ssh/authorized_keys
chattr +i /root/.ssh


chattr -i "${ANSIBLE_HOME}/.ssh" 2> /dev/null
chattr -i "${ANSIBLE_HOME}/.ssh/authorized_keys" 2> /dev/null
userdel -rf ansible 2> /dev/null
useradd --system -d "${ANSIBLE_HOME}" -m -g nogroup -s /bin/bash -c "Ansible maintenance account" -N ansible 2> /dev/null
mkdir -p "${ANSIBLE_HOME}/.ssh"
echo "${ACCOUNT_MAINTENANCE}" > "${ANSIBLE_HOME}/.ssh/authorized_keys"
chown -R ansible:nogroup "${ANSIBLE_HOME}"
chmod -R 0700 "${ANSIBLE_HOME}"
chmod 0600 "${ANSIBLE_HOME}/.ssh/authorized_keys"
if [[ -n "$(which restorecon)" ]]; then restorecon -Rv "${ANSIBLE_HOME}/.ssh"; fi
chattr +i "${ANSIBLE_HOME}/.ssh/authorized_keys"
chattr +i "${ANSIBLE_HOME}/.ssh"

chattr -i /etc/sudoers.d/ansible 2> /dev/null
echo 'ansible  ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/ansible
chattr +i /etc/sudoers.d/ansible
