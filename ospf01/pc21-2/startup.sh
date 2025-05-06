#!/bin/sh

route add default gw 192.168.21.254
route del default gw 192.168.21.1
tail -f /dev/null
