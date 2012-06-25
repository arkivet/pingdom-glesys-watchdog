#!/bin/sh
set -e
cd `dirname $0`
HERE=`pwd`

. $HERE/config.sh

check_glesys()
{
	_TEMP_FILE=`mktemp --tmpdir glesys.XXXXXXXXXX`
	trap "rm -f $_TEMP_FILE; exit" INT TERM EXIT
	$HERE/glesys.sh GET server/status/serverid/$GLESYS_SERVER > $_TEMP_FILE

	_STATUS=`awk '$1 == "/response/server/state" {print $2}' $_TEMP_FILE`

	if [ "$_STATUS" != '"running"' ]; then
		echo "Unexpected status: $_STATUS" >&2
		return
	fi
	
	_UPTIME=`awk '$1 == "/response/server/uptime/current" {print $2}' $_TEMP_FILE`
	if [ "$_UPTIME" -lt $GLESYS_MIN_UPTIME ]; then
		echo "Uptime less than $GLESYS_MIN_UPTIME seconds" >&2
		return
	fi

	_CPU_USAGE=`awk '$1 == "/response/server/cpu/usage" {print $2 * 100}' $_TEMP_FILE`
	echo "CPU usage: $_CPU_USAGE%"
	
	cat $_TEMP_FILE

	if [ "$_CPU_USAGE" -gt "$GLESYS_CPU_USAGE_LIMIT" ]; then
		echo "**** REBOOTING SERVER ****" >&2
		$HERE/glesys.sh POST server/reboot -d serverid=$GLESYS_SERVER
	fi
}


STATUS=`$HERE/pingdom.sh GET checks/$PINGDOM_CHECK | awk '$1 == "/check/status" {print $2}'`

#echo $STATUS

case $STATUS in

	'"down"')
		check_glesys
		;;

esac

