#!/usr/bin/env bash

steam -shutdown

# Turn monitors back on
/etc/profiles/per-user/sylflo/bin/ddcutil --bus=1 setvcp D6 1
/etc/profiles/per-user/sylflo/bin/ddcutil --bus=2 setvcp D6 1
