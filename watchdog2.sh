#!/bin/sh
set -e
cd `dirname $0`
HERE=`pwd`
WATCHDOG_RESULT=`mktemp --tmpdir watchdog.XXXXXXXXXX`
GLESYS_RESULT=`mktemp --tmpdir glesys.XXXXXXXXXX`
LAST_WATCHDOG_RESULT="/tmp/watchdog.last-result"

. $HERE/config.sh


exit_handler()
{ 
	if diff "$LAST_WATCHDOG_RESULT" "$WATCHDOG_RESULT"  >/dev/null 2>&1; then
		:
	else
		cat $WATCHDOG_RESULT
	fi
	cp "$WATCHDOG_RESULT" "$LAST_WATCHDOG_RESULT"

	rm -f "$GLESYS_RESULT" "$WATCHDOG_RESULT"; exit
}

check_glesys()
{
	$HERE/glesys.sh GET server/status/serverid/$GLESYS_SERVER > $GLESYS_RESULT

	_STATUS=`awk '$1 == "/response/status/code" {print $2}' $GLESYS_RESULT`
	if [ "$_STATUS" = '0' ]; then
		# Allow timeouts for now
		return
	fi
	if [ "$_STATUS" != '200' ]; then
		awk 'BEGIN {FS="	"} $1 == "/response/status/text" {print $2}' $GLESYS_RESULT
		return
	fi
	

	_STATE=`awk '$1 == "/response/server/state" {print $2}' $GLESYS_RESULT`
	if [ "$_STATE" != '"running"' ]; then
		if [ "$_STATE" != '"locked"' ]; then
			echo "Unexpected state: $_STATE" >&2
		fi
		#mv /tmp/glesys_get.trace /tmp/glesys_get.trace.`date +%s` || true
		return
	fi
	
	_UPTIME=`awk '$1 == "/response/server/uptime/current" {print $2}' $GLESYS_RESULT`
	if [ "$_UPTIME" -lt $GLESYS_MIN_UPTIME ]; then
#		echo "Uptime less than $GLESYS_MIN_UPTIME seconds" >&2
		return
	fi

	_CPU_USAGE=`awk '$1 == "/response/server/cpu/usage" {print $2 * 100}' $GLESYS_RESULT`
	
	if [ "$_CPU_USAGE" -gt "$GLESYS_CPU_USAGE_LIMIT" ]; then
		echo "CPU usage: $_CPU_USAGE%"
		#cat $GLESYS_RESULT
		echo "**** REBOOTING SERVER ****" >&2
		$HERE/glesys.sh POST server/reboot -d serverid=$GLESYS_SERVER
	fi
}

trap "exit_handler" EXIT INT TERM
check_glesys > $WATCHDOG_RESULT 2>&1

