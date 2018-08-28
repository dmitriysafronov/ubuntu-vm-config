# ubuntu-vm-config
Preconfigure a Ubuntu KVM VM from minimal installation for ansible management


## Example usage

```bash
#!/bin/bash

export ROOTMAIL=your@root.email
export ACCOUNT_EMERGENCY='ssh-rsa YourRootSshPublicKey Emergency account'
export ACCOUNT_MAINTENANCE='ssh-rsa YourAnsibleSshPublicKey Maintenance account'

###

if [[ -n "$(hostname -d)" && -n "${ROOTMAIL}" && -n "${ACCOUNT_EMERGENCY}" && -n "${ACCOUNT_MAINTENANCE}" ]]; then
	wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/install.sh -O ~/ubuntu-vm-config-install.sh
	source ~/ubuntu-vm-config-install.sh
	rm -f ~/ubuntu-vm-config-install.sh 2> /dev/null
	rm -f ~/.wget-hsts 2> /dev/null
	cat /dev/null > ~/.bash_history && history -c
	cat /dev/null > /root/.bash_history && echo "" > /etc/machine-id && sync && poweroff
else
	clear; echo "Set up script first!"
fi
```
