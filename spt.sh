#!/bin/bash
cleanup() {
  echo "Spotifyd has been closed."
  pkill spotifyd
  pkill spotify_player
  exit 0
}

# trap cleanup SIGTERM
trap cleanup SIGHUP

spotifyd &
spotify_player 

cleanup
