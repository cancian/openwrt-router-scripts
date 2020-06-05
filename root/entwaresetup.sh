#!/bin/sh
. /etc/profile.d/colors.inc
self_name="${cyan}Entware installer:${reset}"

# check folder /opt
[ ! -d /opt ] && echo "ERROR! Directory \"/opt\" not found!" && exit 1

# check /opt mounted
if ! grep -q /opt /proc/mounts ; then
	echo "ERROR! Directory \"/opt\" not mounted!"
	exit 1
fi

# check internet
if ! ping -c1 1.1.1.1 1>/dev/null 2>/dev/null; then
  echo "$HOST is down."
  exit 1
fi

INSTALLER=/tmp/entware_installer.sh

# check opkg installed
if [ ! -f /opt/bin/opkg ] ; then
	echo -e "${self_name}" "${yellow}Installing entware opkg....${reset}"
	logger -t "${self_name}" "Installing entware opkg...."
	wget -q http://bin.entware.net/mipselsf-k3.4/installer/generic.sh -O $INSTALLER
	if [ $? -eq 0 ] ; then
		echo -e "${self_name}" "${green}Download script SUCCESS!${reset}"
		logger -t "${self_name}" "Download script SUCCESS!"
	else
		echo -e "${self_name}" "${red}Download script FAILED!${reset}"
		logger -t "${self_name}" "Download script FAILED!"
		exit 1
	fi
        echo -e "${self_name}" "${yellow}Running working script...${reset}"
        logger -t "${self_name}" "Running working script..."
	chmod +x $INSTALLER
	sh $INSTALLER >> $INSTALLER.log 2&>1
        echo -e "${self_name}" "${green}Done SUCCESS...${reset}"
        logger -t "${self_name}" "Done SUCCESS..."
	echo -e "${self_name}" "${yellow}Updating opkg packages list...${reset}"
	logger -t "${self_name}" "Updating opkg packages list..."
	/opt/bin/opkg update
	if [ $? -eq 0 ] ; then
		echo -e "${self_name}" "${green}Packages list update SUCCESS!${reset}"
		logger -t "${self_name}" "Packages list update SUCCESS!"
	else
		echo -e "${red}${self_name}${normal}" "${red}Packages list update FAILED! See ${yellow}$INSTALLER.log ${red}for details.${reset}"
		logger -t "${self_name}" "Packages list update FAILED! See $INSTALLER.log for details."
		exit 1
	fi
	sed -i '/^#.*ru_RU/s/^#//;/^export.*en_US/s/^/#/' /opt/etc/profile
	[ -f /opt/etc/init.d/rc.unslung ] && /opt/etc/init.d/rc.unslung start
	rm -f $INSTALLER $INSTALLER.log
	echo -e "${red}${self_name}" "${green}Congratulations!${reset}"
	echo -e "${red}${self_name}" "${green}If there are no errors above then Entware successfully initialized.${reset}"
	echo -e "${red}${self_name}" "${green}Found a Bug? Please report at https://github.com/Entware/Entware/issues${reset}"
	logger -t "${self_name}" "Congratulations!"
	logger -t "${self_name}" "If there are no errors above then Entware successfully initialized."
	logger -t "${self_name}" "Found a Bug? Please report at https://github.com/Entware/Entware/issues"
else
	echo -e "${self_name}" "WARNING! Entware detected (/opt). Please remove Entware first!"
	logger -t "${self_name}" "WARNING! Entware detected (/opt). Please remove Entware first!"
fi

