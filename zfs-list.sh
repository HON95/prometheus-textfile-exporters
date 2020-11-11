#!/bin/bash

# Script for parsing output from "zfs list" to Prometheus metrics format.
# Example usage: zfs list | zfs-list.sh | sponge zfs-list.prom

set -eu

METRIC_NAMESPACE="node_zfs_zfs_list"
METRIC_USED="${METRIC_NAMESPACE}_used_bytes"
METRIC_AVAIL="${METRIC_NAMESPACE}_available_bytes"
METRIC_REFER="${METRIC_NAMESPACE}_referenced_bytes"

echo "# HELP $METRIC_USED The amount of space consumed by this dataset and its descendants."
echo "# TYPE $METRIC_USED gauge"
echo "# UNIT $METRIC_USED byte"
echo "# HELP $METRIC_AVAIL The amount of space available to this dataset and its descendants."
echo "# TYPE $METRIC_AVAIL gauge"
echo "# UNIT $METRIC_AVAIL byte"
echo "# HELP $METRIC_REFER The amount of space referenced by this dataset."
echo "# TYPE $METRIC_REFER gauge"
echo "# UNIT $METRIC_REFER byte"

parse_iec_number() {
    numfmt --from=iec <<< "$1"
}

parse_line() {
    parts=($@)
    dataset="${parts[0]}"
    mountpoint="${parts[4]}"
    used="$(parse_iec_number ${parts[1]})"
    avail="$(parse_iec_number ${parts[2]})"
    refer="$(parse_iec_number ${parts[3]})"

    echo "$METRIC_USED{dataset=\"$dataset\",mountpoint=\"$mountpoint\"} $used"
    echo "$METRIC_AVAIL{dataset=\"$dataset\",mountpoint=\"$mountpoint\"} $avail"
    echo "$METRIC_REFER{dataset=\"$dataset\",mountpoint=\"$mountpoint\"} $refer"
}

first_line=1
while read line; do
    if [[ $first_line == 1 ]]; then
        first_line=0
        continue
    fi
    parse_line "$line"
done
