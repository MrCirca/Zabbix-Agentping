#!/bin/bash

ZABBIX_TRAP_UNIQUE_NAME=$1
FPING_TARGET=$2
FPING_COUNT=$3
FPING_PERIOD=$4
FPING_BYTES_SIZE=$5
FPING_TIMEOUT=$6
FPING_SRC_IP=$7
FPING_METRIC=$8
FPING_LATENCY_FUNC=$9


FPING_COMMAND="fping -q -c \"$FPING_COUNT\" -p \"$FPING_PERIOD\" -b \"$FPING_BYTES_SIZE\" -t \"$FPING_TIMEOUT\" -S \"$FPING_SRC_IP\" \"$FPING_TARGET\""

ZABBIX_SENDER_COMMAND="zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -i -"

if [ "$8" == "availability" ]; then
    COMMAND="($FPING_COMMAND 2> /dev/null && echo 1 || echo 0)"
    ZABBIX_TRAP_ITEM_KEY="agentping_availability_trap"

elif [ "$8" == "packet_loss" ]; then
    COMMAND="$FPING_COMMAND 2>&1 | egrep -o \"([0-9]+\.)?[0-9]+%\" | tr -d "%""
    ZABBIX_TRAP_ITEM_KEY="agentping_packet_loss_trap"

elif [ "$8" == "latency" ]; then
    COMMAND="$FPING_COMMAND 2>&1 | (egrep -o \"(([0-9]+\.)?[0-9]+/?)+$\" || echo \"0\")"

    case "$FPING_LATENCY_FUNC" in
	"min")
            COMMAND="$COMMAND | cut -d \"/\" -f 1"
            ZABBIX_TRAP_ITEM_KEY="agentping_latency_min_trap"
		;;
	"avg")
            COMMAND="$COMMAND | cut -d \"/\" -f 2"
            ZABBIX_TRAP_ITEM_KEY="agentping_latency_avg_trap"
		;;
	"max")
            COMMAND="$COMMAND | cut -d \"/\" -f 3"
            ZABBIX_TRAP_ITEM_KEY="agentping_latency_max_trap"
		;;
    esac
    
fi

COMMAND="$COMMAND | sed -r 's/.*/- $ZABBIX_TRAP_ITEM_KEY["$ZABBIX_TRAP_UNIQUE_NAME"] \0/g'"
COMMAND="$COMMAND | $ZABBIX_SENDER_COMMAND > /dev/null"

echo $COMMAND | at now &> /dev/null
