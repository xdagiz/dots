#!/bin/bash

TERMINAL="alacritty"
SESSION_NAME="main"
WINDOW_NAME="btop"

# 1. Check if the tmux session exists; if not, just launch a new terminal with btop
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  $TERMINAL -e btop &
  exit 0
fi

# 2. Check if a window named "btop" exists in that session
if tmux list-windows -t "$SESSION_NAME" | grep -q "$WINDOW_NAME"; then
  # If it exists, select it
  tmux select-window -t "$SESSION_NAME:$WINDOW_NAME"
else
  # If it doesn't, create a new window and run btop
  tmux new-window -t "$SESSION_NAME" -n "$WINDOW_NAME" "btop"
fi

# 3. Use Sway to focus the terminal window running the tmux session
swaymsg "[title=\"$SESSION_NAME\"] focus" || swaymsg "[app_id=\"$TERMINAL\"] focus"
