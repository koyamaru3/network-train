#!/bin/sh

route add default gw 10.2.21.254
route del default gw 10.2.21.1
tail -f /dev/null
