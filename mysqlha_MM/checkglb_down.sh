#!/bin/bash

systemctl stop keepalived
pkill keepalived

#cur_time="`date +%Y-%m-%d,%H:%m:%s`"
#echo "Services is down: $cur_time" >> /opt/keepalived_down.log
