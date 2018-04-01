#!/bin/bash

if [[ -z "${ROOTMAIL}" || -z "${ACCOUNT_EMERGENCY}" || -z "${ACCOUNT_MAINTENANCE}" ]]; then
	clear; echo "Set up prerequesites first!"
	break
else
	wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/bootstrap/accounts.sh -O /tmp/ubuntu-vm-config.sh
	source /tmp/ubuntu-vm-config.sh && rm -f /tmp/ubuntu-vm-config.sh 2> /dev/null
	
	wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/bootstrap/software.sh -O /tmp/ubuntu-vm-config.sh
	source /tmp/ubuntu-vm-config.sh && rm -f /tmp/ubuntu-vm-config.sh 2> /dev/null
fi
