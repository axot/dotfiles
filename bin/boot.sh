#!/bin/bash

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') $@"
}

applications=(
  "Alfred 5"
  "BetterDisplay"
  "BetterSnapTool"
  "DisplayLink Manager"
  "Hammerspoon"
  "Mail"
  "Microsoft Outlook"
  "Slack"
  "Usage"
)

# Start each application in parallel
for app in "${applications[@]}"; do
  log "Starting $app..." | tee /tmp/boot.log
  open -a "$app" &
  if [ $? -ne 0 ]; then
    log "Error starting $app"
  fi
done

wait

echo "All applications started."
