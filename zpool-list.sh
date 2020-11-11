#!/bin/bash

# Script for parsing some output from "zpool list" to Prometheus metrics format.
# Example usage: zpool list | zpool-list.sh | sponge zpool-list.prom

set -eu

METRIC_NAMESPACE="node_zfs_zpool_list"
METRIC_SIZE="${METRIC_NAMESPACE}_size_bytes"
METRIC_ALLOC="${METRIC_NAMESPACE}_allocated_bytes"
METRIC_FREE="${METRIC_NAMESPACE}_free_bytes"
METRIC_FRAG="${METRIC_NAMESPACE}_fragmentation"
METRIC_CAP="${METRIC_NAMESPACE}_capacity"
METRIC_DEDUP="${METRIC_NAMESPACE}_deduplication"
METRIC_HEALTH="${METRIC_NAMESPACE}_health_status"

echo "# HELP $METRIC_SIZE The total size of the pool, including redundancy."
echo "# TYPE $METRIC_SIZE gauge"
echo "# UNIT $METRIC_SIZE byte"
echo "# HELP $METRIC_ALLOC The amount of used storage in the pool, including redundancy."
echo "# TYPE $METRIC_ALLOC gauge"
echo "# UNIT $METRIC_ALLOC byte"
echo "# HELP $METRIC_FREE The amount of free storage in the pool, including redundancy."
echo "# TYPE $METRIC_FREE gauge"
echo "# UNIT $METRIC_FREE byte"
echo "# HELP $METRIC_FRAG The ratio of fragmentation in the pool."
echo "# TYPE $METRIC_FRAG gauge"
echo "# UNIT $METRIC_FRAG"
echo "# HELP $METRIC_CAP The ratio of used storage in the pool."
echo "# TYPE $METRIC_CAP gauge"
echo "# UNIT $METRIC_CAP"
echo "# HELP $METRIC_DEDUP The ratio of deduplication in the pool."
echo "# TYPE $METRIC_DEDUP gauge"
echo "# UNIT $METRIC_DEDUP"
echo "# HELP $METRIC_HEALTH A number representing the overall health of the pool. 0 is online, 1 is degraded, 2 is faulted, -1 is unknown."
echo "# TYPE $METRIC_HEALTH gauge"
echo "# UNIT $METRIC_HEALTH"

parse_iec_number() {
    numfmt --from=iec <<< "$1"
}

parse_percentage() {
    awk '{printf "%f\n", $1 / 100}' <<< "$1"
}

parse_mult() {
    grep -Po '^\d+(?:\.\d*)?(?=x)' <<< "$1"
}

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
    size="$(parse_iec_number ${parts[1]})"
    alloc="$(parse_iec_number ${parts[2]})"
    free="$(parse_iec_number ${parts[3]})"
    frag="$(parse_percentage ${parts[6]})"
    cap="$(parse_percentage ${parts[7]})"
    dedup="$(parse_mult ${parts[8]})"
    health="$(parse_health ${parts[9]})"

    echo "$METRIC_SIZE{pool=\"$pool\"} $size"
    echo "$METRIC_ALLOC{pool=\"$pool\"} $alloc"
    echo "$METRIC_FREE{pool=\"$pool\"} $free"
    echo "$METRIC_FRAG{pool=\"$pool\"} $frag"
    echo "$METRIC_CAP{pool=\"$pool\"} $cap"
    echo "$METRIC_DEDUP{pool=\"$pool\"} $dedup"
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
