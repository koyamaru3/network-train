#!/bin/sh

route add default gw 10.1.11.254
route del default gw 10.1.11.1
tail -f /dev/null
