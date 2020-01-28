#!/bin/bash

update_url="https://gitlab.com/MexxIT/multios-usb/-/archive/master/multios-usb-master.tar.bz2?path=config"
config_archive="multios-usb-master-config.tar.bz2"
cur_dir=$(dirname $(readlink -f $0))
man_mount=false

fcn_umount () {
	if [ "$man_mount" = true ]; then
		cd $cur_dir
		sudo umount -f ${device}3
		rmdir mount_USB
	fi
}

echo
echo Multiboot USB config updater
echo
echo Detected devices:
echo ---------------------------------------------
lsblk -p -S -o NAME,TRAN,SIZE,MODEL | grep usb
echo ---------------------------------------------

echo "Enter your USB Device path (e.g. /dev/sdb): "
read -r device
mount_point="$(findmnt ${device}3)"

if [ -z "$mount_point" ]; then
	man_mount=true
	mkdir mount_USB
	sudo mount ${device}3 mount_USB
	mount_point=mount_USB
else
	mount_point="/${mount_point#*/}"
	mount_point="${mount_point%% *}"
fi

check_file="$mount_point/*/config/grub.config"

if [ -f ${check_file[0]} ]; then

	printf '\n'
	printf '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
	printf '++   Are you sure you want to update config files?                                          ++\n'
	printf '++   All modified files in "config" directory will be removed!                              ++\n'
	printf '++   If you have modified any files, please copy them NOW to the "config_priv" directory.   ++\n'
	printf '++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n'
	printf '\n'
	printf 'Type "Yes" to continue: '
	read -r yN
	printf '\n'

	case $yN in
		[Y][e][s])
			true
			;;
		*)
			printf 'Bad answer. Exiting...\n'
			exit 0
			;;
	esac

	cd $(dirname "${check_file[0]}")
	cd ..

	if command -v curl >/dev/null 2>&1; then
		echo -e "\nDownloading..."
		curl $update_url -o $config_archive -s -S
	elif command -v wget >/dev/null 2>&1; then
		echo -e "\nDownloading..."
		wget $update_url -O $config_archive -q
	else
		echo -e "\nPlease install curl or wget to update automaticaly your configuration files.\n"
		exit 1
	fi

	if bzip2 -t "$config_archive" &>/dev/null ; then
		rm -r -f config
		tar -xjf $config_archive --no-same-owner --strip-components=1
		rm $config_archive
	else 
		echo -e "\nError!!! File: $config_archive does not exist or is corrupted.\n"
		fcn_umount
		exit 1
	fi

	echo -e "\nYour config files are up to date.\n"

	fcn_umount
	exit 0
else
	echo
	echo Error: Multiboot USB is not installed on this USB!
	echo
	fcn_umount
	exit 1
fi
