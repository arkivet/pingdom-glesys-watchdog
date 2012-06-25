#!/bin/sh
SERVER=$1
`dirname $0`/glesys.sh POST server/reboot -d serverid=$SERVER
