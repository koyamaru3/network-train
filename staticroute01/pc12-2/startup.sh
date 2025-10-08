#!/bin/sh

route add default gw 10.1.12.254
route del default gw 10.1.12.1
tail -f /dev/null
