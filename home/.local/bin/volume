#!/usr/bin/bash

function is_mute {
  pactl get-sink-mute @DEFAULT_SINK@
}

case $1 in
up)
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02+ -l 1.0
  volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
  notify-send -e -h string:x-canonical-private-synchronous:volume -h int:value:"${volume}" -t 800 "Volume: ${volume}%"
  ;;
down)
  wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.02-
  volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
  notify-send -e -h string:x-canonical-private-synchronous:volume -h int:value:"${volume}" -t 800 "Volume: ${volume}%"
  ;;
mute)
  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  if [[ $(is_mute) == "Mute: yes" ]]; then
    notify-send 'Muted' -h string:x-canonical-private-synchronous:volume-notification
  else
    notify-send 'Unmuted' -h string:x-canonical-private-synchronous:volume-notification
  fi
  ;;
esac
