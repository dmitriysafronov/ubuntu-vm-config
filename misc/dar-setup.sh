#!/bin/bash

# Domain access reconfigurator
wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/sbin/reconfigure-domain-access -O /usr/local/sbin/reconfigure-domain-access
chown root:root /usr/local/sbin/reconfigure-domain-access
chmod 0750 /usr/local/sbin/reconfigure-domain-access
/usr/local/sbin/reconfigure-domain-access
head -n -1 /etc/rc.local > /tmp/rc.local.tmp; grep -q '/usr/local/sbin/reconfigure-domain-access' /tmp/rc.local.tmp || `echo -e "/usr/local/sbin/reconfigure-domain-access\n\nexit 0" >> /tmp/rc.local.tmp; cat /tmp/rc.local.tmp > /etc/rc.local`

#
