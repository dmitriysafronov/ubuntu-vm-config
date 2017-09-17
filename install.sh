#!/bin/bash

A_BOOTSTRAPS=accounts.sh software.sh

if [[ -z "$(hostname -d)" || -z "${ROOTMAIL}" || -z "${ACCOUNT_EMERGENCY}" || -z "${ACCOUNT_MAINTENANCE}" ]]; then
	clear; echo "Set up prerequesites first!"
else
	for A_BOOTSTRAP in ${A_BOOTSTRAPS}; do
		wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/bootstrap/${A_BOOTSTRAP} -O /tmp/ubuntu-vm-config.sh
		source /tmp/ubuntu-vm-config.sh && rm -f /tmp/ubuntu-vm-config.sh 2> /dev/null
	done
fi
