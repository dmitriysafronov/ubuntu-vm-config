#!/bin/bash

if [[ -z "${ACCOUNT_EMERGENCY}" || -z "${ACCOUNT_MAINTENANCE}" ]]; then
	clear; echo "Export SSH keys fisrt!"
	exit 1
fi

export MAINTENANCE_HOME='/var/opt/maintenance'

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
#chattr +i /root/.ssh/authorized_keys

#######

chattr -i "${MAINTENANCE_HOME}/.ssh" 2> /dev/null
chattr -i "${MAINTENANCE_HOME}/.ssh/authorized_keys" 2> /dev/null
userdel -rf maintenance 2> /dev/null
useradd --system -d "${MAINTENANCE_HOME}" -m -g nogroup -s /bin/bash -c "Maintenance account" -N maintenance 2> /dev/null
mkdir -p "${MAINTENANCE_HOME}/.ssh"
echo "${ACCOUNT_MAINTENANCE}" > "${MAINTENANCE_HOME}/.ssh/authorized_keys"
chown -R maintenance:nogroup "${MAINTENANCE_HOME}"
chmod -R 0700 "${MAINTENANCE_HOME}"
chmod 0600 "${MAINTENANCE_HOME}/.ssh/authorized_keys"
if [[ -n "$(which restorecon)" ]]; then restorecon -Rv "${MAINTENANCE_HOME}/.ssh"; fi
#chattr +i "${MAINTENANCE_HOME}/.ssh/authorized_keys"

chattr -i /etc/sudoers.d/maintenance 2> /dev/null
echo 'maintenance  ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/maintenance
#chattr +i /etc/sudoers.d/maintenance
