#!/bin/bash

# Prerequisites: Ubuntu-minimal 16.04 installed only w/ openssh-server, FQDN hostname, root email exported as ROOTMAIL

if [[ -z "${ROOTMAIL}" ]]; then
	ROOTMAIL=root@mail
fi

###############################################################

# Part 0. Step: InitRamFS - ZSWAP LZ4 compressor
grep -q -w 'lz4' /etc/initramfs-tools/modules || echo lz4 >> /etc/initramfs-tools/modules
grep -q -w 'lz4_compress' /etc/initramfs-tools/modules || echo lz4_compress >> /etc/initramfs-tools/modules
update-initramfs -u

# Part 0. Step: Bootloader - ZSWAP
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

# Part 1: Preparation
echo -e "deb http://ru.archive.ubuntu.com/ubuntu/ bionic main restricted universe multiverse
deb http://ru.archive.ubuntu.com/ubuntu/ bionic-updates main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu bionic-security main restricted universe multiverse" > /etc/apt/sources.list
apt update

# Step: software - essential - pt.1
apt install -y debconf-utils

# Step: iptables-persistent
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install -y iptables-persistent

# Step: localepurge
echo "localepurge localepurge/use-dpkg-feature boolean false" | debconf-set-selections
echo "localepurge localepurge/nopurge multiselect C.UTF-8" | debconf-set-selections
echo "localepurge localepurge/dontbothernew boolean false" | debconf-set-selections
echo "localepurge localepurge/showfreedspace boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install -y localepurge
update-locale --reset LANG=ru_RU.UTF-8
localepurge

# Step: postfix
echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
echo "postfix postfix/mailname string $(hostname -f)" | debconf-set-selections
echo "postfix postfix/root_address string ${ROOTMAIL}" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confnew" install --no-install-recommends -y postfix

# Step: postfix reconfigurator
wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/sbin/reconfigure-postfix -O /usr/local/sbin/reconfigure-postfix
chown root:root /usr/local/sbin/reconfigure-postfix
chmod 0750 /usr/local/sbin/reconfigure-postfix
/usr/local/sbin/reconfigure-postfix
head -n -1 /etc/rc.local > /tmp/rc.local.tmp; grep -q '/usr/local/sbin/reconfigure-postfix' /tmp/rc.local.tmp || `echo -e "/usr/local/sbin/reconfigure-postfix\n\nexit 0" >> /tmp/rc.local.tmp; cat /tmp/rc.local.tmp > /etc/rc.local`

# Step: hostname reconfigurator
wget https://github.com/DmitriySafronov/ubuntu-vm-config/raw/master/sbin/reconfigure-hostname -O /usr/local/sbin/reconfigure-hostname
chown root:root /usr/local/sbin/reconfigure-hostname
chmod 0750 /usr/local/sbin/reconfigure-hostname

# Step: mail alert on (re-)start
head -n -1 /etc/rc.local > /tmp/rc.local.tmp; grep -q 'ip a | tail -n +7 | mail -s "System (re-)started: \$(hostname)" root' /tmp/rc.local.tmp || `echo 'ip a | tail -n +7 | mail -s "System (re-)started: \$(hostname)" root' >> /tmp/rc.local.tmp; echo -e "\nexit 0" >> /tmp/rc.local.tmp; cat /tmp/rc.local.tmp > /etc/rc.local`

# Step: software - essential - pt.2
apt install -y linux-image-virtual s-nail unattended-upgrades systemd-cron vim-tiny

# Step: unattended-upgrades setup
echo -e "APT::Periodic::Update-Package-Lists \"1\";
APT::Periodic::Unattended-Upgrade \"1\";" > /etc/apt/apt.conf.d/20auto-upgrades

echo -e "Unattended-Upgrade::Allowed-Origins {
        \"\${distro_id}:\${distro_codename}\";
        \"\${distro_id}:\${distro_codename}-security\";
        \"\${distro_id}:\${distro_codename}-updates\";
};
Unattended-Upgrade::AutoFixInterruptedDpkg \"true\";
Unattended-Upgrade::MinimalSteps \"true\";
Unattended-Upgrade::InstallOnShutdown \"false\";
Unattended-Upgrade::Mail \"root\";
Unattended-Upgrade::MailOnlyOnError \"false\";
Unattended-Upgrade::Remove-Unused-Dependencies \"true\";
Unattended-Upgrade::Automatic-Reboot-Time \"03:00\";
Unattended-Upgrade::Automatic-Reboot \"true\";" > /etc/apt/apt.conf.d/50unattended-upgrades

# Step: software - additional
apt install -y --no-install-recommends qemu-guest-agent

###############################################################

# Part 2: Cleanup & upgrade

# Step: cleanup 1
apt purge -y open-iscsi lxd lxd-client lxcfs lxc-common snapd screen byobu
apt purge -y language-pack-en language-pack-ru less laptop-detect os-prober dmidecode dictionaries-common emacsen-common wamerican wbritish wireless-regdb linux-generic linux-firmware linux-headers accountsservice installation-report libx11-data xdg-user-dirs eject language-selector-common libdiscover2 libxml2 pciutils usbutils cron libpam-systemd
apt autoremove --purge -y

# Step: upgrade
apt full-upgrade -y

## Step: cleanup 2
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
