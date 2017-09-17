# ubuntu-vm-config
Preconfigure a Ubuntu KVM VM from minimal installation for ansible management


## Example usage

```bash
#!/bin/bash

echo "root:YourVerySecretRootPassword" | chpasswd

echo ROOTMAIL=your@root.email > ~/.ubuntu-vm-config
echo ACCOUNT_EMERGENCY='ssh-rsa YourRootSshPublicKey Emergency account' >> ~/.ubuntu-vm-config
echo ACCOUNT_MAINTENANCE='ssh-rsa YourAnsibleSshPublicKey Maintenance account' >> ~/.ubuntu-vm-config

#######

if [[ -n "$(hostname -d)" ]]; then
	wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/install.sh -O ~/ubuntu-vm-config-install.sh
	bash ~/ubuntu-vm-config-install.sh
	rm -f ~/ubuntu-vm-config-install.sh 2> /dev/null
	rm -f ~/.wget-hsts 2> /dev/null
	cat /dev/null > ~/.bash_history && history -c
	cat /dev/null > /root/.bash_history && sync && poweroff
else
	clear; echo "Set up script first!"
fi
```