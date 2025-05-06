#!/bin/sh

route add default gw 192.168.12.254
route del default gw 192.168.12.1
tail -f /dev/null
