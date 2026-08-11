#!/usr/bin/env bash

DEV="sda"

DATA=$(iostat -d -m -o JSON 1 2)

READ=$(echo "$DATA" |
  jq -r --arg d "$DEV" \
    '.sysstat.hosts[0].statistics[1].disk[] 
       | select(.disk_device == $d) 
       | ."MB_read/s"')

WRITE=$(echo "$DATA" |
  jq -r --arg d "$DEV" \
    '.sysstat.hosts[0].statistics[1].disk[] 
       | select(.disk_device == $d) 
       | ."MB_wrtn/s"')

[ -z "$READ" ] && READ="0"
[ -z "$WRITE" ] && WRITE="0"

# printf "{\"text\":\" ${READ}MB/s  ${WRITE}MB/s\"}"
# printf '{"text":" %s MB/s"}' "$READ"
printf '{"text":" %s MB/s  %s MB/s"}' "$READ" "$WRITE"
