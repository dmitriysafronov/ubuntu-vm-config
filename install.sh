#!/bin/bash

if [[ -n "$(hostname -d)" && -n "${ROOTMAIL}" && -n "${ACCOUNT_EMERGENCY}" && -n "${ACCOUNT_MAINTENANCE}" ]]; then
	clear; echo "Set up prerequesites first!"
	exit 1
else
	wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/bootstrap/accounts.sh -O /tmp/ubuntu-vm-config.sh
	call /tmp/ubuntu-vm-config.sh && rm -f /tmp/ubuntu-vm-config.sh 2> /dev/null
	
	wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/bootstrap/software.sh -O /tmp/ubuntu-vm-config.sh
	call /tmp/ubuntu-vm-config.sh && rm -f /tmp/ubuntu-vm-config.sh 2> /dev/null
fi
