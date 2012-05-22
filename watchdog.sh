#!/bin/sh
PINGDOM_URL=https://api.pingdom.com/api/2.0
GLESYS_URL=https://api.glesys.com

. `dirname $0`/config.sh

pingdom_get()
{
	_RESOURCE=$1
	curl --silent --header "App-Key: $PINGDOM_KEY" -u "$PINGDOM_USER:$PINGDOM_PASSWORD" $PINGDOM_URL/$_RESOURCE | jsonpipe
}


check_glesys()
{
echo "TODO: check glesys API and reboot if needed"
}


STATUS=`pingdom_get checks/$PINGDOM_CHECK | awk '$1 == "/check/status"{ print $2}'`

case $STATUS in

	"down")
		check_glesys
		;;

esac

