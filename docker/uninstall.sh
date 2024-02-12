#!/bin/bash
function UNINSTALL() {
	for i in $(awk '/deepin-wine/{print $1}' < <(docker ps -a)); do
		docker stop $i && docker rm $i
	done
	###stop docker container
	for i in $(docker images > >(awk '$1~/deepin-wine/{print $3}')); do
		docker rmi $i
	done
	###remove docker image
	echo "Unstall done"
}

while :; do
	read -p "Are you sure uninstall the project?[Y/N]:"
	case ${REPLY} in
	'Y' | 'y')
		UNINSTALL && exit 0
		;;
	'N' | 'n')
		echo 'Abort.'
		exit 0
		;;
	*)
		echo 'Input error,please input again!'
		continue
		;;
	esac
done
