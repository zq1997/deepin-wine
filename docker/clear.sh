#!/bin/bash
# Empty the docker container.
# We recommend to clean it at least once a month, this tool can be combined with
# crontab, which means you don't need to do it manually.
# This script also will empty APP_PATH subfile, you can backup it before cleaning if you want.
function CLEAR_CONTAINER() {
	for i in $(awk '/deepin-wine/{print $1}' < <(docker ps -a)); do
		docker stop $i && docker rm $i
	done

}
while true; do
	read -p 'Are you sure clear the docker container for deepin-wine?[Y/N]'
	case ${REPLY} in
	'Y' | 'y')
		sudo rm -rf APP_PATH/*
		CLEAR_CONTAINER && echo 'clear done' && exit 0
		;;
	'N' | 'n')
		echo 'Abort.'
		exit 0
		;;
	*)
		echo -e 'Sorry,input error,please input again\n' && continue
		;;
	esac
done
