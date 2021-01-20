#!/bin/bash

# Name: Prometheus textfile exporter for ZFS zfs list.
# Description:
#   Script for parsing output from "zfs list -Hp" to Prometheus metrics format.
#   Example usage: zfs list -Hp | ./zfs-list.sh | sponge zfs-list.prom
# Type: Prometheus textfile exporter
# Author: HON
# Version: 1.1.0
# Changes
#   1.1.0: Add calculated size.
#   1.0.0: Initial release.

set -eu

METRIC_NAMESPACE="node_zfs_zfs_list"
METRIC_USED="${METRIC_NAMESPACE}_used_bytes"
METRIC_AVAIL="${METRIC_NAMESPACE}_available_bytes"
METRIC_REFER="${METRIC_NAMESPACE}_referenced_bytes"
METRIC_SIZE="${METRIC_NAMESPACE}_size_bytes"

echo "# HELP $METRIC_USED The amount of space consumed by this dataset and its descendants."
echo "# TYPE $METRIC_USED gauge"
echo "# UNIT $METRIC_USED byte"
echo "# HELP $METRIC_AVAIL The amount of space available to this dataset and its descendants."
echo "# TYPE $METRIC_AVAIL gauge"
echo "# UNIT $METRIC_AVAIL byte"
echo "# HELP $METRIC_REFER The amount of space referenced by this dataset."
echo "# TYPE $METRIC_REFER gauge"
echo "# UNIT $METRIC_REFER byte"
echo "# HELP $METRIC_SIZE The sum of the amount of used and available space (calculated)."
echo "# TYPE $METRIC_SIZE gauge"
echo "# UNIT $METRIC_SIZE byte"

parse_line() {
    parts=($@)
    dataset="${parts[0]}"
    mountpoint="${parts[4]}"
    used="${parts[1]}"
    avail="${parts[2]}"
    refer="${parts[3]}"
    size="$((parts[1] + parts[2]))"

    echo "$METRIC_USED{dataset=\"$dataset\",mountpoint=\"$mountpoint\"} $used"
    echo "$METRIC_AVAIL{dataset=\"$dataset\",mountpoint=\"$mountpoint\"} $avail"
    echo "$METRIC_REFER{dataset=\"$dataset\",mountpoint=\"$mountpoint\"} $refer"
    echo "$METRIC_SIZE{dataset=\"$dataset\",mountpoint=\"$mountpoint\"} $size"
}

while read line; do
    parse_line "$line"
done
