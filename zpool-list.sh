#!/bin/bash

# Script for parsing some output from "zpool list" to Prometheus metrics format.
# Example usage: zpool list | zpool-list.sh | sponge zpool-list.prom

set -eu

METRIC_NAMESPACE="node_zfs_zpool_list"
METRIC_HEALTH="${METRIC_NAMESPACE}_health_status"

echo "# HELP $METRIC_HEALTH A number representing the health of the system. 0 is online, 1 is degraded, 2 is faulted, -1 is unknown."
echo "# TYPE $METRIC_HEALTH gauge"
echo "# UNIT $METRIC_HEALTH"

parse_health() {
    if [[ $1 == "ONLINE" ]]; then
        echo 0
    elif [[ $1 == "DEGRADED" ]]; then
        echo 1
    elif [[ $1 == "FAULTED" ]]; then
        echo 2
    else
        echo -1
    fi
}

parse_line() {
    parts=($@)
    pool="${parts[0]}"
    health_str="${parts[9]}"
    health="$(parse_health $health_str)"

    echo "$METRIC_HEALTH{pool=\"$pool\"} $health"
}

first_line=1
while read line; do
    if [[ $first_line == 1 ]]; then
        first_line=0
        continue
    fi
    parse_line "$line"
done
