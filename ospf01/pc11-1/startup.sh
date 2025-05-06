#!/bin/sh

route add default gw 192.168.11.254
route del default gw 192.168.11.1
tail -f /dev/null
