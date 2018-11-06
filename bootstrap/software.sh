#!/bin/bash

# Prerequisites: Ubuntu-minimal installed only w/ openssh-server, FQDN hostname, root email exported as ROOTMAIL

if [[ -z "${ROOTMAIL}" ]]; then
	ROOTMAIL=root@mail
fi

if [[ -z "${MONITORING_SERVER}" ]]; then
	MONITORING_SERVER=monitoring.local
fi

###############################################################

# Step: Preparation
echo -e "deb http://ru.archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse
deb http://ru.archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" > /etc/apt/sources.list
wget -q https://repo.zabbix.com/zabbix/4.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.0-2+bionic_all.deb -O /tmp/zabbix-release.deb
dpkg -i /tmp/zabbix-release.deb
rm -f /tmp/zabbix-release.deb
sed -e 's/^deb-src/#deb-src/g' -i /etc/apt/sources.list.d/zabbix.list
apt update

# Step: software - essential - pt.1
apt install -y debconf-utils

# Step: postfix
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $(hostname -f)" | debconf-set-selections
echo "postfix postfix/root_address string ${ROOTMAIL}" | debconf-set-selections
echo "postfix postfix/protocols select ipv4" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install --no-install-recommends -y postfix

# Step: software - essential - pt.2
apt install -y unattended-upgrades vim-tiny s-nail systemd-cron
# linux-image-virtual-hwe-16.04-edge

update-alternatives --install /usr/bin/mail mail /usr/bin/s-nail 0

###############################################################

# Step: iptables-persistent
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install -y iptables-persistent
if [[ ! -d /proc/sys/net/ipv6 ]]; then
	chmod a-x /usr/share/netfilter-persistent/plugins.d/25-ip6tables
	echo 'DPkg::Post-Invoke {"chmod a-x /usr/share/netfilter-persistent/plugins.d/25-ip6tables";};' > /etc/apt/apt.conf.d/99-zz-disable-ipv6-save
	rm /etc/iptables/rules.v6
	netfilter-persistent save
fi

# Step: localepurge
echo "localepurge localepurge/use-dpkg-feature boolean false" | debconf-set-selections
echo "localepurge localepurge/nopurge multiselect C.UTF-8" | debconf-set-selections
echo "localepurge localepurge/dontbothernew boolean false" | debconf-set-selections
echo "localepurge localepurge/showfreedspace boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install -y localepurge
update-locale --reset LANG=C.UTF-8
localepurge

###############################################################

# Step: software - additional
apt install -y --no-install-recommends qemu-guest-agent zabbix-agent

# Step: zabbix-agent setup
systemctl enable zabbix-agent
echo -e "############ GENERAL PARAMETERS #################
PidFile=/run/zabbix/zabbix_agentd.pid
LogType=system

##### Remote commands
EnableRemoteCommands=0
LogRemoteCommands=1

##### Passive checks related
Server=${MONITORING_SERVER}
ListenPort=10050
StartAgents=3

##### Active checks related
ServerActive=${MONITORING_SERVER}
HostnameItem=system.hostname
HostMetadataItem=system.uname

############ ADVANCED PARAMETERS #################
Include=/etc/zabbix/zabbix_agentd.d/*.conf" > /etc/zabbix/zabbix_agentd.conf

# Step: rsyslog-remote setup
echo -e "# Remote logging to monitoring server
*.* @${MONITORING_SERVER}" > /etc/rsyslog.d/zz-rsyslog-sender.conf

###############################################################

# Step: Cleanup 1
apt purge -y open-iscsi lxd lxd-client lxcfs lxc-common snapd cron libpam-systemd update-manager-core update-notifier-common \
eject screen byobu update-motd language-selector-common language-pack-* dictionaries-common emacsen-common wamerican wbritish \
accountsservice installation-report libx11-data xdg-user-dirs laptop-detect os-prober dmidecode wireless-regdb libdiscover2 libxml2 \
pciutils usbutils linux-firmware linux-generic* linux-headers* landscape-common plymouth* \
at ufw overlayroot ubuntu-advantage-tools ubuntu-release-upgrader-core nano \
libntfs-3g* dosfstools lshw popularity-contest
apt autoremove --purge -y

###############################################################

# Step: InitRamFS - ZSWAP LZ4 compressor
grep -q -w 'lz4' /etc/initramfs-tools/modules || echo lz4 >> /etc/initramfs-tools/modules
grep -q -w 'lz4_compress' /etc/initramfs-tools/modules || echo lz4_compress >> /etc/initramfs-tools/modules
update-initramfs -u

# Step: Bootloader - ZSWAP
grep -v '#' /etc/default/grub | grep -w 'GRUB_CMDLINE_LINUX=' | tail -n 1 > /tmp/grub.cmdline
echo -e "GRUB_DEFAULT=0
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR=\`lsb_release -i -s 2> /dev/null || echo Debian\`
GRUB_CMDLINE_LINUX_DEFAULT=\"zswap.enabled=1 zswap.compressor=lz4\"
GRUB_TERMINAL=console
GRUB_DISABLE_OS_PROBER=true" > /etc/default/grub
cat /tmp/grub.cmdline >> /etc/default/grub
rm -f /tmp/grub.cmdline
update-grub

###############################################################

if [[ ! -x /etc/rc.local ]]; then
echo -e "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will \"exit 0\" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0" > /etc/rc.local
	chmod ug+x /etc/rc.local
fi

###############################################################

# Step: postfix reconfigurator
wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/sbin/reconfigure-postfix -O /usr/local/sbin/reconfigure-postfix
chown root:root /usr/local/sbin/reconfigure-postfix
chmod 0750 /usr/local/sbin/reconfigure-postfix

# Step: hostname reconfigurator
wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/sbin/reconfigure-hostname -O /usr/local/sbin/reconfigure-hostname
chown root:root /usr/local/sbin/reconfigure-hostname
chmod 0750 /usr/local/sbin/reconfigure-hostname

# Step: unattended-upgrades setup
echo -e "APT::Periodic::Update-Package-Lists \"1\";
APT::Periodic::Unattended-Upgrade \"1\";" > /etc/apt/apt.conf.d/20auto-upgrades

echo -e "Unattended-Upgrade::Origins-Pattern {
      \"o=*\";
};
Unattended-Upgrade::AutoFixInterruptedDpkg \"true\";
Unattended-Upgrade::MinimalSteps \"true\";
Unattended-Upgrade::InstallOnShutdown \"false\";
Unattended-Upgrade::Mail \"root\";
Unattended-Upgrade::MailOnlyOnError \"false\";
Unattended-Upgrade::Remove-Unused-Dependencies \"true\";
Unattended-Upgrade::Automatic-Reboot-Time \"03:00\";
Unattended-Upgrade::Automatic-Reboot \"true\";" > /etc/apt/apt.conf.d/50unattended-upgrades

###############################################################

# Step: additional setup
/usr/local/sbin/reconfigure-postfix

# STFU MOTD-NEWS
systemctl stop motd-news.timer
systemctl stop motd-news.service
systemctl disable motd-news.timer
systemctl disable motd-news.service
echo -e "ENABLED=0" > /etc/default/motd-news

###############################################################

# Step: Swap & swappiness
fallocate -l 128M /swapfile
chmod 600 /swapfile
mkswap /swapfile
cat /etc/fstab > /tmp/fstab.tmp; grep -q '/swapfile none swap sw 0 0' /tmp/fstab.tmp || `echo '/swapfile none swap sw 0 0' >> /tmp/fstab.tmp; cat /tmp/fstab.tmp > /etc/fstab`
echo -e "vm.swappiness=0
vm.vfs_cache_pressure=50" > /etc/sysctl.d/98-swappiness.conf

###############################################################

# Step: Cleanup 2
apt autoremove --purge -y

# Step: upgrade
apt full-upgrade -y

## Step: cleanup 3
# Unattended-upgrades
rm -f /etc/apt/apt.conf.d/20auto-upgrades.ucf-dist
rm -f /etc/apt/apt.conf.d/50unattended-upgrades.ucf-dist

# APT
apt clean
rm -f /var/lib/apt/lists/*/* 2> /dev/null
rm -f /var/lib/apt/lists/* 2> /dev/null

# DHCP
rm -rf /var/lib/dhcp/* 2> /dev/null

# DBUS
rm -rf /var/lib/dbus/* 2> /dev/null

# Logrotate
rm -rf /var/lib/logrotate/* 2> /dev/null

# Urandom
rm -rf /var/lib/urandomdev/null

# Supervise
rm -rf /var/lib/supervise

# update-manager
rm -rf /var/lib/update-manager

# release-upgrader
rm -rf /var/lib/ubuntu-release-upgrader

# Journal (if any)
rm -rf /var/log/journal/* 2> /dev/null

# LOGs
rm -f /var/log/*/* 2> /dev/null
rm -f /var/log/* 2> /dev/null

touch /var/log/lastlog
chown root:utmp /var/log/lastlog
chmod 0664 /var/log/lastlog

touch /var/log/dmesg
chown root:adm /var/log/dmesg
chmod 0640 /var/log/dmesg

touch /var/log/faillog
chown root:root /var/log/faillog
chmod 0644 /var/log/faillog

# sync
sync
