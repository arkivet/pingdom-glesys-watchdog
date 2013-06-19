#!/bin/bash
PINGDOM_URL=https://api.pingdom.com/api/2.0

. `dirname $0`/config.sh

METHOD=$1
shift
RESOURCE=$1
shift

from_json()
{
	if read -n 0; then
		/usr/local/bin/jsonpipe
	fi
}

pingdom_get()
{
	_RESOURCE=$1
	curl --silent --header "App-Key: $PINGDOM_KEY" -u "$PINGDOM_USER:$PINGDOM_PASSWORD" $PINGDOM_URL/$_RESOURCE | from_json
}


case $METHOD in 

	GET)
		pingdom_get "$RESOURCE"
		;;

	*)
		exit 1
		;;

esac

