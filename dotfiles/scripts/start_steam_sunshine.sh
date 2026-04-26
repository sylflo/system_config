#!/usr/bin/env bash
setpriv --inh-caps=-all --ambient-caps=-all -- \
  gamescope -W 1920 -H 1080 -r 60 -f -e -- steam -bigpicture -tenfoot
